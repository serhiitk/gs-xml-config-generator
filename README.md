# Grandstream XML Configuration File Generator  

This shell script is used to generate a batch of XML configuration files from the two input files TXT and CSV.

The TXT format file stores all the “same” values of P-values and the CSV format file stores the “various” value of P-values.

Before executing this script, please put the TXT and CSV files at the same path, then execute the `gs_xml_config_generator.sh` with three passed parameter `$1`, `$2`, `$3`:

- `$1` is the location of TXT and CSV files without a trailing slash '/' at the end, e.g. '/home/user/work'

( **NOTE**: you can use `.` if the script locates with TXT and CSV files at the same location );

- `$2` is the full name of the TXT file, e.g. 'config_template.txt';
- `$3` is the full name of the CSV file, e.g. 'MAC_users.csv'.

It will generate different XML files named by every MAC address named as cfg*MAC*.xml use the same TXT config-template, and the XML files will be output at the location defined in variable OUTPUT_PATH

( **NOTE**: default value is `OUTPUT_PATH="$1/gs_xml_config.d"` ).
