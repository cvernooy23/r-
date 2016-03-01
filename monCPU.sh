a=$(iostat -c 15 1 | grep -A 1 "%idle" | awk 'NR>1' | awk '{print $6}')
nagioscheck=0

#function taken from http://www.linuxjournal.com/content/floating-point-math-bash
function float_eval()
{
    local stat=0
    local result=0.0
    if [[ $# -gt 0 ]]; then
        result=$(echo "scale=$float_scale; $*" | bc -q 2>/dev/null)
        stat=$?
        if [[ $stat -eq 0  &&  -z "$result" ]]; then stat=1; fi
    fi
    echo $result
    return $stat
}

#function taken from http://www.linuxjournal.com/content/floating-point-math-bash
function float_cond()
{
    local cond=0
    if [[ $# -gt 0 ]]; then
        cond=$(echo "$*" | bc -q 2>/dev/null)
        if [[ -z "$cond" ]]; then cond=0; fi
        if [[ "$cond" != 0  &&  "$cond" != 1 ]]; then cond=0; fi
    fi
    local stat=$((cond == 0))
    return $stat
}

function report_bad()
{
if [[ $nagioscheck == 1 ]]; then
    echo "1"
else
    echo "Warning :: $error"
fi
}

function report_good()
{
if [[ $nagioscheck == 1 ]]; then
   echo "0"
else
   echo "OK: $check"
fi
}

##CPU Check if not using a monitor system or if not included or not working right##
if $(float_cond '$a > 5.00'); then
   perc=$(bc <<< "100-$a")
   error="CPU @ $perc%"
   report_bad
else
   perc=$(bc <<< "100-$a")
   check="CPU @ $perc%"
   report_good
fi

##Check for zombie procs and output##
zProcs=$(ps aux | awk '{ print $8 " " $2 }' | grep -w Zz)

if [ $zProcs ]; then
   error="Zombie processes detected, use kill -9 to kill. $zProcs"
   report_bad
else
   check="No Zombie procs detected"
   report_good
fi

##Check for diskspace##
badDiskAr=()
i=0
for d in $(df -H | awk 'NR>1' | awk '{print $5}'); do 
   if [ `echo $d | tr -d .% > 85` ]; then 
       #badDiskAr[$i]=`echo "$d"`
       if [ $i == 0 ]; then        
          error="Partition `df -H | awk 'NR>1' | head -1 | awk '{print $6 "/" $1}'` is @ $d"
          report_bad
       else
          ci=$i+1
          error="Partition `df -H | awk 'NR>1' | head -$ci | tail -1 | awk '{print $6 "/" $1}'` is @ $d"
          report_bad
       fi
   else
       check="Partition `df -H | awk 'NR>1' | grep $d | awk '{print $6}'` is @ $d"
       report_good
   fi
   let i+=1
done

