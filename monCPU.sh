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
    echo "Warning :: CPU @ $a"
fi
}

report_good()
{
if [[ $nagioscheck == 1 ]]; then
   echo "0"
else
   echo "ok $a"
fi
}

if $(float_cond '$a > 5.00'); then
	if [[ $nagioscheck == 1 ]]; then 
	    echo "1"
	else
 	    echo "Warning :: CPU @ $a"
	fi
else
	if [[ $nagioscheck == 1 ]]; then 
	    echo "0"
	else
 	    echo "ok $a"
	fi
fi

zProcs=$(ps aux | awk '{ print $8 " " $2 }' | grep -w Zz)

if [ $zProcs ]; then
   report_bad
else
   report_good
fi

