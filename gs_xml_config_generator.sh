#!/bin/bash

# check if the user have inputed the $1 $2 $3, if not, quit and give a hint.
if [ ! -n "$1" ] || [ ! -n "$2" ] || [ ! -n "$3" ] ; then
	echo "    you have not input the \$1 or \$2 or \$3"
	echo "        Please input \$1 as the path of the TXT and CSV files, without a trailing slash '/' at the end"
	echo "        Please input \$2 as the name of the TXT file, end with '.txt'"
	echo "        Please input \$3 as the name of the CSV file, end with '.csv'"
	exit 1
else

OUTPUT_PATH="$1/gs_xml_config.d"

if [ ! -d "$OUTPUT_PATH" ] ; then
	mkdir -p $OUTPUT_PATH
fi

###############################################################################
# Generate XML config template from TXT file
###############################################################################

# after command inputed correctly, create a tmp file.
touch $1/tmp1.xml

# add the XML declaration
echo "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>" >> $1/tmp1.xml
echo "<!-- Grandstream XML Provisioning Configuration -->" >> $1/tmp1.xml
echo "<gs_provision version=\"1\">" >> $1/tmp1.xml
echo "<mac></mac>" >> $1/tmp1.xml
echo "  <config version=\"1\">" >> $1/tmp1.xml

# read the content of the TXT template into the tmp file
cat $1/$2 >> $1/tmp2.xml

# delete the Unicode BOM as the <feff> at the txt, if there is any.
# delete all the ^M sigh caused by the txt editor.
sed -i -e 's/^\xEF\xBB\xBF//' -e "s///g" $1/tmp2.xml

# remove all Space characters (include tabs) from left to the first word,
# remove all lines contained only '#' with or without Space characters,
# clear all lines started NOT with '#' or 'P'
# comment all lines started with '#' in XML style
sed -e 's/^[[:space:]]*//' -e '/^#\+[#[:space:]]*$/d' -e 's/^[^#P]*$//' \
		-e '/^#/ s:.*:<!--&-->:' -e '/<!--/ s:#::g'                         \
		-e 's/<!--[[:space:]]*/<!-- /' -e 's/[[:space:]]*-->/ -->/'         \
				$1/tmp2.xml >> $1/tmp3.xml

# remove all non-valid lines
sed -e '/^<\|^$\|^P[0-9]\{1,5\}[[:space:]]*=.*$/ !d' \
				$1/tmp3.xml >> $1/tmp4.xml

# convert XML skip characters into character entity references,
# add <> </> to P-value every configuration line,
# remove all leading and trailing Space characters in P-value
sed -e '/^P/ s:&:&amp;:g' -e '/^P/ s:<:\&lt;:g' -e '/^P/ s:>:\&gt;:g'       \
		-e '/^P/ s:'\'':\&apos;:g' -e '/^P/ s:'\"':\&quot;:g'                   \
		-e '/^P/ s:[[:space:]]*=:===:' -e '/^P/ s:\(.*\)===\(.*\):<\1>\2</\1>:' \
		-e 's/>[[:space:]]*/>/g' -e 's/[[:space:]]*</</g'                       \
				$1/tmp4.xml >> $1/tmp5.xml

# add the start of XML declaration
cat $1/tmp1.xml >> $1/tmp6.xml

# add generated XML configuration template
cat $1/tmp5.xml >> $1/tmp6.xml

# add the end of XML declaration
echo "  </config>" >> $1/tmp6.xml
echo "</gs_provision>" >>$1/tmp6.xml

###############################################################################
# CSV file preparation:
###############################################################################
# remove all leading and trailing Space characters in line and CSV cells,
# remove all empty lines and lines with blank MAC value,
# remove all the ^M sigh caused by the txt editor
sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'           \
		-e 's/,[[:space:]]\+/,/g' -e 's/[[:space:]]\+,/,/g'     \
		-e '/^$/d' -e '/^,/d' -e "s///g" \
				$1/$3 > $1/tmp7.csv

###############################################################################
# Generate XML configuration files
# read the CSV file and generate all the XML files by the information in the CSV file.
###############################################################################

IFS=','
exec 5<&0
exec < $1/tmp7.csv

read -a header
while read -a line; do

  # check if the MAC address matches the prefix of GS devices
  if [[ "${line[0]}" == *"000B82"* ]] || [[ "${line[0]}" == *"000b82"* ]] || \
		 [[ "${line[0]}" == *"C074AD"* ]] || [[ "${line[0]}" == *"c074ad"* ]]; then

		MAC=` echo ${line[0]} | tr '[:upper:]' '[:lower:]' `
		cat "$1/tmp6.xml" > "$OUTPUT_PATH/cfg$MAC.xml"

		for i in "${!line[@]}"; do

			if grep -q "^<${header[i]}" "$OUTPUT_PATH/cfg$MAC.xml" ; then
				sed -i -e "/^<${header[i]}>/ s:.*:<${header[i]}>${line[i]}</${header[i]}>:g" \
							 -e "s///g"                                                            \
									"$OUTPUT_PATH/cfg$MAC.xml"
			else
				sed -i -e "/^[[:space:]]*<\/config>/i <${header[i]}>${line[i]}</${header[i]}>" \
									"$OUTPUT_PATH/cfg$MAC.xml"
			fi

		done

		sed -i -e "/^<P/s:<P:    <P:" -e "1,5!s/^<!--/    <!--/" \
							"$OUTPUT_PATH/cfg$MAC.xml"

  else

    echo "        Notice: The Mac \"${line[0]}\" is invalid for not starting with \"000B82\" or \"C074AD\", please check the CSV file"

  fi

done

exec 0<&5
unset IFS

#delete all the tmp files
rm $1/tmp1.xml $1/tmp2.xml $1/tmp3.xml $1/tmp4.xml $1/tmp5.xml $1/tmp6.xml $1/tmp7.csv

#end of if-statement
fi

#give a hint where the XML is outputed
echo "        Thank you for using this program!"
echo "        Your XML files will be generated at: $OUTPUT_PATH"
