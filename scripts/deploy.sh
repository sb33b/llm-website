#!/usr/bin/env bash
# Build this site and sync the output to its cPanel document root over SSH.
#
#   npm run deploy                # build, preview changes, confirm, upload
#   npm run deploy -- --dry-run   # build and preview only; changes nothing
#   npm run deploy -- --skip-build
#   npm run deploy -- --yes       # no confirmation prompt
#
# Connection settings live in .env.deploy (gitignored); see .env.deploy.example.
# The remote folder is mirrored exactly: files not in the new build are
# deleted, except protected paths (DEFAULT_PROTECT + DEPLOY_PROTECT).
#
# This file is shared by llm-portal and llm-website; only the SITE block
# below differs between them.
set -euo pipefail

# ── SITE ─────────────────────────────────────────────────────────────────────
SITE_NAME="llm-website"
BUILD_DIR="dist"
build() { npm run build; }
# ─────────────────────────────────────────────────────────────────────────────

# Never deleted or overwritten on the server. cPanel/host-managed files plus
# the deploy marker. Add more with DEPLOY_PROTECT in .env.deploy.
DEFAULT_PROTECT=".well-known cgi-bin .user.ini php.ini error_log .deployed-by"
MARKER=".deployed-by"

DRY_RUN=0
SKIP_BUILD=0
ASSUME_YES=0
for arg in "$@"; do
	case "$arg" in
		--dry-run) DRY_RUN=1 ;;
		--skip-build) SKIP_BUILD=1 ;;
		--yes | -y) ASSUME_YES=1 ;;
		-h | --help)
			sed -n '2,13p' "$0" | sed 's/^# \{0,1\}//'
			exit 0
			;;
		*)
			echo "Unknown option: $arg" >&2
			exit 2
			;;
	esac
done

cd "$(dirname "$0")/.."
die() {
	echo "✗ $*" >&2
	exit 1
}

# ── config ───────────────────────────────────────────────────────────────────
[ -f .env.deploy ] || die "Missing .env.deploy. Copy .env.deploy.example and fill it in."
set -a
# shellcheck disable=SC1091
. ./.env.deploy
set +a

: "${DEPLOY_HOST:?DEPLOY_HOST is not set in .env.deploy}"
: "${DEPLOY_USER:?DEPLOY_USER is not set in .env.deploy}"
: "${DEPLOY_PATH:?DEPLOY_PATH is not set in .env.deploy}"
DEPLOY_PORT="${DEPLOY_PORT:-21098}"
DEPLOY_PROTECT="${DEPLOY_PROTECT:-}"

# A bare hostname only: not the cPanel URL (https://…:2083) or a path.
case "$DEPLOY_HOST" in
	*://* | */* | *:*)
		die "DEPLOY_HOST must be a bare hostname like server197.web-hosting.com (no https://, path or :port). Got '$DEPLOY_HOST'."
		;;
esac
case "$DEPLOY_PORT" in
	'' | *[!0-9]*) die "DEPLOY_PORT must be a number (Namecheap SSH is 21098). Got '$DEPLOY_PORT'." ;;
	2083 | 2082) die "DEPLOY_PORT $DEPLOY_PORT is cPanel's web port, not SSH. Namecheap SSH is 21098." ;;
esac

# Refuse paths that could point at the home directory or escape it.
REMOTE_PATH="${DEPLOY_PATH%/}"
case "$REMOTE_PATH" in
	"" | "/" | "." | "~" | "~/" | /home | "/home/$DEPLOY_USER" | *..*)
		die "DEPLOY_PATH '$DEPLOY_PATH' is not a safe deploy target. Point it at the site's document root."
		;;
esac

# Key auth only: never fall back to a password prompt.
SSH_OPTS=(-p "$DEPLOY_PORT" -o ConnectTimeout=15 -o PreferredAuthentications=publickey -o PasswordAuthentication=no
	-o ControlMaster=auto -o "ControlPath=/tmp/llm-deploy-%C" -o ControlPersist=120)
# (/tmp, not $TMPDIR: macOS TMPDIR paths can exceed the 104-char socket limit.)
if [ -n "${DEPLOY_SSH_KEY:-}" ]; then
	SSH_OPTS+=(-i "${DEPLOY_SSH_KEY/#\~/$HOME}" -o IdentitiesOnly=yes)
fi
TARGET="$DEPLOY_USER@$DEPLOY_HOST"
remote() { ssh "${SSH_OPTS[@]}" "$TARGET" "$@"; }

# ── build ────────────────────────────────────────────────────────────────────
if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
	echo "⚠ Working tree has uncommitted changes; they will be deployed."
fi

if [ "$SKIP_BUILD" -eq 0 ]; then
	echo "▸ Building ${SITE_NAME}…"
	build
fi
[ -f "$BUILD_DIR/index.html" ] || die "$BUILD_DIR/index.html not found. Did the build succeed?"
[ -f "$BUILD_DIR/.htaccess" ] || echo "⚠ $BUILD_DIR/.htaccess is missing; the server will run without it."

# ── remote checks ────────────────────────────────────────────────────────────
echo "▸ Connecting to $TARGET:${DEPLOY_PORT}…"
remote true ||
	die "Could not connect over SSH. Check DEPLOY_HOST/DEPLOY_PORT/DEPLOY_USER, that SSH access is enabled in cPanel, and that your key is authorized."
remote "test -d '$REMOTE_PATH'" ||
	die "Remote folder '$REMOTE_PATH' does not exist (relative paths start in the home directory). Create it in cPanel first."

# The marker records which site owns the folder, so swapped paths are caught
# before the mirror deletes another site's files.
owner="$(remote "cat '$REMOTE_PATH/$MARKER' 2>/dev/null | head -1" || true)"
if [ -n "$owner" ] && [ "$owner" != "$SITE_NAME" ]; then
	die "'$REMOTE_PATH' was last deployed by '$owner', not '$SITE_NAME'. Check DEPLOY_PATH."
fi

EXCLUDES=()
for p in $DEFAULT_PROTECT $DEPLOY_PROTECT; do
	EXCLUDES+=(--exclude "$p")
done

# -c: compare by checksum, not size+mtime, so a rebuilt file of the same size
# is never skipped. Flags limited to what macOS openrsync supports.
RSYNC=(rsync -rlt -c -z --delete "${EXCLUDES[@]}" -e "ssh ${SSH_OPTS[*]}")
SRC="$BUILD_DIR/"
DEST="$TARGET:$REMOTE_PATH/"

# ── preview ──────────────────────────────────────────────────────────────────
echo "▸ Changes for $DEST"
preview="$("${RSYNC[@]}" -n -v "$SRC" "$DEST")"
changes="$(printf '%s\n' "$preview" | grep -vE '^(sending|sent |total size|building file list|Transfer starting|\./?$|$)' || true)"
deletions="$(printf '%s\n' "$changes" | grep -c '^deleting ' || true)"
uploads="$(printf '%s\n' "$changes" | grep -v '^deleting ' | grep -cv '/$' || true)"
if [ -n "$changes" ]; then
	printf '%s\n' "$changes" | sed 's/^/  /'
fi
echo "  → $uploads file(s) to upload, $deletions to delete"

if [ "$DRY_RUN" -eq 1 ]; then
	echo "✓ Dry run only; nothing was changed."
	exit 0
fi
if [ -z "$changes" ]; then
	echo "✓ Server is already up to date."
	exit 0
fi

if [ "$ASSUME_YES" -eq 0 ]; then
	printf 'Deploy %s to %s? [y/N] ' "$SITE_NAME" "$DEST"
	read -r answer
	case "$answer" in
		y | Y | yes | YES) ;;
		*) die "Cancelled." ;;
	esac
fi

# ── deploy ───────────────────────────────────────────────────────────────────
"${RSYNC[@]}" "$SRC" "$DEST"
commit="$(git rev-parse --short HEAD 2>/dev/null || echo unknown)"
remote "printf '%s\n%s\n%s\n' '$SITE_NAME' '$commit' '$(date -u +%Y-%m-%dT%H:%M:%SZ)' > '$REMOTE_PATH/$MARKER'"
echo "✓ Deployed $SITE_NAME ($commit) to $DEST"
