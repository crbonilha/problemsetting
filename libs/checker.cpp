#include "checker.h"
#include <stdio.h>

bool is_eof(bool print_if_not_eof) {
	int new_line_char = getc(stdin);
	int eof_char = getc(stdin);
	if(new_line_char != 10 or eof_char != EOF) {
		if(print_if_not_eof) printf("wrong should be EOF but isnt,");
		return false;
	}
	return true;
}
