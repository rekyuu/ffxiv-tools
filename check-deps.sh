#!/bin/bash

. helpers/prompt.sh
. helpers/error.sh
. helpers/deps.sh

HARD_DEPS_32=(  )
HARD_DEPS_64=( libpng12.so.0 libFAudio.so.0 )

SOFT_DEPS_32=(  )
SOFT_DEPS_64=( libgcrypt.so )

HARD_TOOLS=( unzip patchelf )
SOFT_TOOLS=( winetricks )

MISSING_HARD_32=(  )
MISSING_HARD_64=(  )
MISSING_SOFT_32=(  )
MISSING_SOFT_64=(  )

MISSING_HARD_TOOLS=(  )
MISSING_SOFT_TOOLS=(  )

MISSING_HARD_MISC=(  )
MISSING_SOFT_MISC=(  )

echo "Checking for dependencies..."

echo "Checking required 32-bit dependencies..."

for DEP in "${HARD_DEPS_32[@]}"; do
    CHECK_DEP_32 "$DEP"
    if [[ "$?" -eq 0 ]]; then
        success "Found dependency $DEP..."
    else
        error "Missing dependency $DEP..."
        MISSING_HARD_32+=("$DEP")
    fi
done

echo "Checking required 64-bit dependencies..."

for DEP in "${HARD_DEPS_64[@]}"; do
    CHECK_DEP_64 "$DEP"
    if [[ "$?" -eq 0 ]]; then
        success "Found dependency $DEP..."
    else
        error "Missing dependency $DEP..."
        MISSING_HARD_64+=("$DEP")
    fi
done

echo "Checking recommended 32-bit dependencies..."

for DEP in "${SOFT_DEPS_32[@]}"; do
    CHECK_DEP_32 "$DEP"
    if [[ "$?" -eq 0 ]]; then
        success "Found dependency $DEP..."
    else
        warn "Missing dependency $DEP..."
        MISSING_SOFT_32+=("$DEP")
    fi
done

echo "Checking recommended 64-bit dependencies..."

for DEP in "${SOFT_DEPS_64[@]}"; do
    CHECK_DEP_64 "$DEP"
    if [[ "$?" -eq 0 ]]; then
        success "Found dependency $DEP..."
    else
        warn "Missing dependency $DEP..."
        MISSING_SOFT_64+=("$DEP")
    fi
done

echo "Checking for required tools..."

for DEP in "${HARD_TOOLS[@]}"; do
    CHECK_TOOL "$DEP"
    if [[ "$?" -eq 0 ]]; then
        success "Found tool $DEP..."
    else
        error "Missing tool $DEP..."
        MISSING_HARD_TOOLS+=("$DEP")
    fi
done

echo "Checking for optional tools..."

for DEP in "${SOFT_TOOLS[@]}"; do
    CHECK_TOOL "$DEP"
    if [[ "$?" -eq 0 ]]; then
        success "Found tool $DEP..."
    else
        warn "Missing tool $DEP..."
        MISSING_SOFT_TOOLS+=("$DEP")
    fi
done

echo "Checking miscellaneous requirements..."

ULIMIT="$(ulimit -Hn)"
if [[ "$ULIMIT" -lt 524288 ]]; then
    warn "Detected a low ulimit value ($ULIMIT)."
    warn "This will cause slow .NET Framework installation and may impact game performance."
    MISSING_SOFT_MISC+=("ulimit")
fi

echo
echo

if [[ $ERRORS -gt 0 ]]; then
    error "Required dependencies are missing."
    . dependency-resolvers/detect.sh
    if [[ ! "$(type RESOLVE_DEPS)" = RESOLVE_DEPS\ is\ a\ function* ]]; then
        error "Failed to load dependency resolver"
        exit 1
    fi
    RESOLVE_DEPS
elif [[ $WARNINGS -gt 0 ]]; then
    warn "Optional dependencies are missing."
    . dependency-resolvers/detect.sh
    if [[ ! "$(type RESOLVE_DEPS)" = RESOLVE_DEPS\ is\ a\ function* ]] || [[ "$(type RESOLVE_DEPS)" = *No\ dependency\ resolver\ was\ found\ for\ your\ distro* ]]; then
        warn "Failed to load dependency resolver. You can continue without resolving soft dependencies."
        PROMPT_CONTINUE
    else
        RESOLVE_DEPS
    fi
else
    success "All required and recommended dependencies and tools found."
fi
