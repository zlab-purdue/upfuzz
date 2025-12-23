f=$(find failure -iname 'inconsistency_*' | sort -t '_' -k2,2n | head -n 1)
if [ -n "$f" ]; then
  cat "$f"
else
  echo "Bug is not triggered"
fi
