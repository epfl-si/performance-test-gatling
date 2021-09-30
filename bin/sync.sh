cdown() {
  res=$(curl "${SYNC}/$1?id=${NAME}" 2>/dev/null)
  echo "cdown $1 -> $res" >&2
  echo >&2
  echo $res
}

if [ -n "${SYNC}" ] ; then
  if [ -n "${CI}" ] ; then
    ci=$CI
  else
    ci=300
  fi
  if [ -n "${CTO}" ] ; then
    let cto=$(date +%s)+3600
  else
    let cto=$(date +%s)+$cto
  fi

  echo "====================================== Syncing..."
  res=$(cdown check)
  if [[ "$res" == "Ok" ]] ; then
    echo "=== Sync server Ok"
    res=$(cdown register)
    if [[ "$res" == "Ok" ]] ; then
      echo "=== Client registered"
      while [[ $(date +%s) -lt $cto ]] ; do
        res=$(cdown get)
        if [ "$res" == "0" ] ; then
          let n=$(date +%s)
          let cto=($n-$n%$ci)+$ci
          let s=$cto-$n
          echo "=== All clients are ready. Sleeping $s. Target: $cto"
          sleep $s
        else
          echo "=== Still $res clients missing. Sleeping $ci."
          sleep $ci
        fi
      done
    fi
  else
    echo "=============================== !! Sync server check failed."
  fi
fi
