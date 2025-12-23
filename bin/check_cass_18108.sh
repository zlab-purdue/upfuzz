find failure -iname "fullstop_crash" | sort -t '_' -k2,2n | head -n 1
if [ -n "$f" ]; then
  cat "$f"
else
  echo "Bug is not triggered"
fi

