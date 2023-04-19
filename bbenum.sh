#!/bin/bash

echo "making directory"
mkdir $1

echo "collecting resolver"
dnsvalidator -tL https://public-dns.info/nameservers.txt -threads 20 -o resolvers.txt 
sort -R resolver.txt | tail -n 50 > 50resolver.txt

echo "starting amass"
amass enum -d $1 -passive -o amass_subdomain.txt

echo "starting subfinder"
subfinder -d $1 -silent -t 100 -nc -all > subfinder_subdomain.txt

echo "bruteforcing"
puredns bruteforce /opt/OneListForAll/dict/subdomains_short.txt $1 -w puredns_bf_domain.txt -r 50resolver.txt

echo "combining subdomain"
cat amass_subdomain.txt subfinder_subdomain.txt puredns_bf_domain.txt | sort -u | anew collected_subdomain.txt

echo "starting gotator"
gotator -sub collected_subdomain.txt -perm /opt/OneListForAll/dict/permutations_list.txt -dept 1 -number 10 -mindup -adv -md -silent > subs_to_resolve.txt

echo "resolving subs"
puredns resolve subs_to_resolve.txt -r 50resolver.txt --write valid_alt_domain.txt

echo "finding urls"
cat collected_subdomain.txt | gau --blacklist png,jpg,jpeg,img,svg,mp3,mp4,eot,woff1,woff2 > gaus.txt

echo "collecting data with httpx"
cat gaus.txt | httpx -sc -td -server -ip -cname -mc 200 -x POST GET TRACE OPTIONS -json -o httpx.json


