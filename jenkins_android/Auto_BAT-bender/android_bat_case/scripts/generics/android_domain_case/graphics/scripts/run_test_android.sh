#!/system/bin/sh
ROOT="`dirname $0`"
IGT_TEST_ROOT="$ROOT/"
RESULTS="$ROOT/results"

if [ ! -d "$IGT_TEST_ROOT" ]; then
    echo "Error: could not find tests directory."
    exit 1
fi

function print_help {
        echo "Usage: run-tests.sh [options]"
        echo "Available options:"
        echo "  -h              display this help message"
        echo "  -l              list all available tests"
        #echo "  -r <directory>  store the results in directory"
        #echo "                  (default: $RESULTS)"
        #echo "  -s              create html summary"
        #echo "  -t <regex>      only include tests that match the regular expression"
        #echo "                  (can be used more than once)"
        echo "  -T <filename>   run tests listed in testlist"
        #echo "                  (overrides -t and -x)"
        #echo "  -v              enable verbose mode"
        echo "  -x <regex>      exclude tests that match the regular expression"
        echo "                  (can be used more than once)"
        echo "  -R              resume interrupted test where the partial results"
        echo "                  are in the results directory"
        #echo "  -n              do not retry incomplete tests when resuming a"
        #echo "                  test run with -R"
        echo ""
        echo "Useful patterns for test filtering are described in the API documentation."
}

function list_tests {
    check_file
    cat $"$IGT_TEST_ROOT/$FILE" | ( while read LINE
    do
        echo $LINE
    done)
    exit
}

function check_file {
    if [ ! -f ${IGT_TEST_ROOT}/${FILE} ]; then
        echo "Error: test list not found, run tests listed in testlist"
        echo "E. g: -T fast-feedback.testlist"
        exit 1
    fi
    if [ -d "$RESULTS" ]; then
        rm -fr $RESULTS
    fi
    mkdir $RESULTS
    if [[ $FILE == *"kms"* ]]; then
        log=$RESULTS"/kms_log.log"
        result=$RESULTS"/kms_result.txt"
    elif [[ $FILE == *"fast"* ]]; then
        log=$RESULTS"/bat_log.log"
        result=$RESULTS"/bat_result.txt"
    fi
}

function resume_test {
    check_file
    last_test="`tail -2 $result | sed -n '/igt@/p' | sed -e 's/\n//g'`"
    last_result="`tail -1 $result`"
    cat ${IGT_TEST_ROOT}/${FILE} | ( while read LINE
    do
        if [ $LINE == $last_test ]; then
            if [[ $last_result == *"igt@"* ]]; then
                resume_run="true"
                if [[ $LINE == *"igt@"* ]]; then
                    test=${LINE#*igt@}
                    echo $LINE | tee -a $log
                    if [[ $EXCLUDE == *$LINE* ]]; then
                        echo "Subtest ${test#*@} Excluded" | tee -a $log | tee -a  $result
                        continue
                    else
                        if [[ $test == *@* ]]; then
                            ./$IGT_TEST_ROOT/${test%@*} --run-subtest ${test#*@} | tee -a $log
                        else
                            ./$IGT_TEST_ROOT/$test | tee -a $log
                        fi
                        last_line="`tail -1 $log`"
                        if [[ $last_line == *SUCCESS* || $last_line == *SKIP* || $last_line == *FAIL* ]]; then
                            tail -1 $log >> $result
                        else
                            echo "Subtest ${test#*@} No Valid" | tee -a $log | tee -a  $result
                        fi
                        continue
                    fi
                fi
            else
                resume_run="true"
                continue
            fi
        fi
        if [ "x$resume_run" != "x" ]; then
            if [[ $LINE == *"igt@"* ]]; then
                test=${LINE#*igt@}
                echo $LINE | tee -a $log | tee -a $result
                if [[ $test == *@* ]]; then
                    ./$IGT_TEST_ROOT/${test%@*} --run-subtest ${test#*@} | tee -a $log
                else
                    ./$IGT_TEST_ROOT/$test | tee -a $log
                fi
                last_line="`tail -1 $log`"
                if [[ $last_line == *SUCCESS* || $last_line == *SKIP* || $last_line == *FAIL* ]]; then
                    tail -1 $log >> $result
                else
                    echo "Subtest ${test#*@} No Valid" | tee -a $log | tee -a  $result
                fi
            fi
        fi
    done)
}

function run_test {
    check_file
    if [ -f "$log" ]; then
        rm $log
    fi
    if [ -d "$result" ]; then
        rm $result
    fi
    cat ${IGT_TEST_ROOT}/${FILE} | ( while read LINE
    do
        if [[ $LINE == *"igt@"* ]]; then
            test=${LINE#*igt@}
            echo $LINE | tee -a $log | tee -a $result
            if [[ $EXCLUDE == *$LINE* ]]; then
                echo "Subtest ${test#*@} Excluded" | tee -a $log | tee -a  $result
                continue
            else
                if [[ $test == *@* ]]; then
                    ./$IGT_TEST_ROOT/${test%@*} --run-subtest ${test#*@} | tee -a $log
                else
                    ./$IGT_TEST_ROOT/$test | tee -a $log
                fi
                last_line="`tail -1 $log`"
                if [[ $last_line == *SUCCESS* || $last_line == *SKIP* || $last_line == *FAIL* ]]; then
                    tail -1 $log >> $result
                else
                    echo "Subtest ${test#*@} No Valid" | tee -a $log | tee -a  $result
                fi
            fi
        fi
    done)
}

while getopts ":hlRx:T:" opt; do
    case $opt in
        h) print_help; exit ;;
        T) FILE="$FILE$OPTARG" ;;
        l) LISTTEST="true" ;;
        R) RESUME="true" ;;
        x) EXCLUDE="$EXCLUDE -x $OPTARG" ;;
        :)
            echo "Option -$OPTARG requires an argument."
            exit 1
            ;;
        \?)
            echo "Unknown option: -$OPTARG"
            print_help
            exit 1
            ;;
    esac
done

shift $(($OPTIND-1))

if [ "x$LISTTEST" != "x" ]; then
    list_tests
fi

if [ "x$RESUME" != "x" ]; then
    resume_test
else
    run_test
fi
