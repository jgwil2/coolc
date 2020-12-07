/*
 *  The scanner definition for COOL.
 */

/*
 *  Stuff enclosed in %{ %} in the first section is copied verbatim to the
 *  output, so headers and global definitions are placed here to be visible
 * to the code in the file.  Don't remove anything that was here initially
 */
%{
#include <cool-parse.h>
#include <stringtab.h>
#include <utilities.h>

/* The compiler assumes these identifiers. */
#define yylval cool_yylval
#define yylex  cool_yylex

/* Max size of string constants */
#define MAX_STR_CONST 1025
#define YY_NO_UNPUT   /* keep g++ happy */

extern FILE *fin; /* we read from this file */

/* define YY_INPUT so we read from the FILE fin:
 * This change makes it possible to use this scanner in
 * the Cool compiler.
 */
#undef YY_INPUT
#define YY_INPUT(buf,result,max_size) \
	if ( (result = fread( (char*)buf, sizeof(char), max_size, fin)) < 0) \
		YY_FATAL_ERROR( "read() in flex scanner failed");

char string_buf[MAX_STR_CONST]; /* to assemble string constants */
char *string_buf_ptr;

extern int curr_lineno;
extern int verbose_flag;

extern YYSTYPE cool_yylval;

/*
 *  Add Your own definitions here
 */


%}

/*
 * Define names for regular expressions here.
 */

LETTER          [a-zA-Z_]
DIGIT           [0-9]
DIGITS          [0-9]+

TYPEID          [A-Z]({LETTER}|{DIGIT})*
OBJECTID        [a-z]({LETTER}|{DIGIT})*

TRUE            true
FALSE           false


DARROW          =>
ASSIGN          <-

DBL_QT          \"

%x STRING

%%

 /*
  *  Nested comments
  */


 /*
  *  The multiple-character operators.
  */
{DARROW}        { return (DARROW); }
{ASSIGN}        { return (ASSIGN); }


[ \f\r\t\v]           // eat up whitespace
"\n" { curr_lineno++; }

 /*
  * Keywords are case-insensitive except for the values true and false,
  * which must begin with a lower-case letter.
  */

(?i:class)      { return (CLASS); }
(?i:else)       { return (ELSE); }
(?i:fi)         { return (FI); }
(?i:if)         { return (IF); }
(?i:in)         { return (IN); }
(?i:inherits)   { return (INHERITS); }
(?i:let)        { return (LET); }
(?i:loop)       { return (LOOP); }
(?i:pool)       { return (POOL); }
(?i:then)       { return (THEN); }
(?i:while)      { return (WHILE); }
(?i:case)       { return (CASE); }
(?i:esac)       { return (ESAC); }
(?i:new)        { return (NEW); }
(?i:isvoid)     { return (ISVOID); }

"{"             { return '{'; }
"}"             { return '}'; }
"["             { return '['; }
"]"             { return ']'; }
"("             { return '('; }
")"             { return ')'; }
":"             { return ':'; }
";"             { return ';'; }
","             { return ','; }
"+"             { return '+'; }
"-"             { return '-'; }
"*"             { return '*'; }
"/"             { return '/'; }
"="             { return '='; }
"<"             { return '<'; }
"."             { return '.'; }
"@"             { return '@'; }
"~"             { return '~'; }

{TRUE}          {
                    cool_yylval.boolean = true;
                    return BOOL_CONST;
                }

{FALSE}         {
                    cool_yylval.boolean = false;
                    return BOOL_CONST;
                }

{TYPEID}        {
                    cool_yylval.symbol = idtable.add_string(yytext);
                    return TYPEID;
                }

{OBJECTID}      {
                    cool_yylval.symbol = idtable.add_string(yytext);
                    return OBJECTID;
                }

{DIGITS}        {
                    cool_yylval.symbol = inttable.add_string(yytext);
                    return INT_CONST;
                }

 /*
  *  String constants (C syntax)
  *  Escape sequence \c is accepted for all characters c. Except for 
  *  \n \t \b \f, the result is c.
  *
  */

char string_buf[MAX_STR_CONST];
char* string_buf_ptr;

{DBL_QT}        {   /* set pointer to 0-index of string buffer */
                    string_buf_ptr = string_buf;
                    BEGIN(STRING);
                }

<STRING>{DBL_QT} {  /* closing quote - terminate string and */
                    /* return token type and value to parser */
                    BEGIN(INITIAL);
                    *string_buf_ptr = '\0';
                    cool_yylval.symbol = stringtable.add_string(string_buf);
                    return STR_CONST;
                }

<STRING>\n      { /* TODO handle unterminated str const err */ }

    /* whitespace chars */
<STRING>\\n     { *string_buf_ptr++ = '\n'; }
<STRING>\\t     { *string_buf_ptr++ = '\t'; }
<STRING>\\r     { *string_buf_ptr++ = '\r'; }
<STRING>\\b     { *string_buf_ptr++ = '\b'; }
<STRING>\\f     { *string_buf_ptr++ = '\f'; }

    /* remove? */
<STRING>\\(.|\n) {
                    *string_buf_ptr++ = yytext[1];
                }

<STRING>[^\\\n({DBL_QT})] {
                    char* yptr = yytext;

                    while (*yptr) {
                        *string_buf_ptr++ = *yptr++;
                    }
                }

%%
