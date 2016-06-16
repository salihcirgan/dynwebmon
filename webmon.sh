#!/bin/bash
DNSServer=127.0.0.1
zone=MyDNSZone
mydomain=MyDomain
TTL=60
dnsiplist=( $(dig +short @$DNSServer $mydomain | grep '[0-5]') )
httpstatus=()
index=0
downips=()
upips=()

for i in ${dnsiplist[@]}

do
        echo "checking $i"

        if curl -m 5 -s -k --head --request GET $i | grep -q "200 OK" 
        then
            httpstatus[index]=up
                  upips+=($i)
        else
            httpstatus[index]=down
                  downips+=($i)
        fi
        let index=index+1
done

index=0

function ipadd () {

if [ -n "$upips"  ] ;

then

echo server $DNSServer >> /tmp/nsupdateadd
echo debug yes >> /tmp/nsupdateadd
echo "zone $zone." >> /tmp/nsupdateadd

for ipu in ${upips[@]}

do

echo "update add $mydomain $TTL A $ipu" >> /tmp/nsupdateadd

done

echo "send" >> /tmp/nsupdateadd
echo `nsupdate -k /etc/bind/key.txt -v /tmp/nsupdateadd`
echo "DNS records of $upips are added"
echo -n "" > /tmp/nsupdateadd

fi

}

function ipdel () {

if [ -n "$downips" ] ;

then

echo server $DNSServer >> /tmp/nsupdatedel
echo debug yes >> /tmp/nsupdatedel
echo "zone $zone." >> /tmp/nsupdatedel

for ipd in ${downips[@]}

do

echo "update delete $mydomain A $ipd" >> /tmp/nsupdatedel

done

echo "send" >> /tmp/nsupdatedel
echo `nsupdate -k /etc/bind/key.txt -v /tmp/nsupdatedel`
echo "Deleted records of ${downips[@]} "
echo -n "" > /tmp/nsupdatedel

fi

}

doesipexist () {

    local array="$1[@]"
    local wantedip=$2
    local in=1
    for ip in "${!array}"; do
        if [[ $ip == $wantedip ]]; then
            in=0
            break
        fi
    done
    return $in
}


doesipexist dnsiplist ${upips[@]} && ipadd
doesipexist dnsiplist ${downips[@]} && ipdel
