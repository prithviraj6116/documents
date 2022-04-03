function headertrees_clean
system('find . -name "*_MIXED.cpp_i" -exec rm -f {} \;');
system('find . -name "*.cpp_headertree" -exec rm -f {} \;');
system('find . -name "*.cpp_headerlist_classified" -exec rm -f {} \;');
system('find . -name "*.cpp_headerlist_unclassified" -exec rm -f {} \;');
system('find . -name "*.cpp_summary" -exec rm -f {} \;');
end