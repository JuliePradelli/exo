#! /bin/bash

#a="CA_tata"

#sed "/$a/,/policy_match/d" a.txt >b.txt
#mv b.txt a.txt
#ligne=`grep -n "$a" a.txt`
#if [[ ! -z "$ligne" ]]
#then
#	num=`echo $ligne | cut -d':' -f1`
#	sed -i".sav" "$num d" a.txt
#fi
sed -i -e '/coucu/d' test.txt
