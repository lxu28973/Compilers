/*
 *  The scanner definition for COOL.
 */

/*
 *  Stuff enclosed in %{ %} in the first section is copied verbatim to the
 *  output, so headers and global definitions are placed here to be visible
 * to the code in the file.  Don't remove anything that was here initially
 */
%option noyywrap
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

int str_len = 0;

%}

%x STRING
%x WAIT_STRING_END
%x LINE_COMMENT
%x BLOCK_COMMENT

/*
 * Define names for regular expressions here.
 */

/* Keywords */
CLASS           [cC][lL][aA][sS]{2}
ELSE            [eE][lL][sS][eE]
FALSE           f[aA][lL][sS][eE]
FI              (?i:fi)
IF              (?i:if)
IN              (?i:in)
INHERITS        (?i:inherits)
LET             (?i:let)
LOOP            (?i:loop)
POOL            (?i:pool)
THEN            (?i:then)
WHILE           (?i:while)
CASE            (?i:case)
ESAC            (?i:esac)
OF              (?i:of)
NEW             (?i:new)
ISVOID          (?i:isvoid)
NOT             (?i:not)
TRUE            t[rR][uU][eE]

DARROW          =>
INT             [0-9]+

TYPEID          [A-Z][a-zA-z_0-9]*
OBJECTID        [a-z][a-zA-z_0-9]*
ASSIGN          "<-"
LE              "<="




%%

\n            { curr_lineno++; }
[ \t\r\v\f]+	{}

 /*
  *  Nested comments
  */

"--"			{ BEGIN LINE_COMMENT; }
"(\*"			{ BEGIN BLOCK_COMMENT; }
"\*)"			{	cool_yylval.error_msg = "Unmatched *)";
          	return (ERROR); }

<LINE_COMMENT>\n		{ BEGIN 0; curr_lineno++; }
<LINE_COMMENT>.			{}

<BLOCK_COMMENT>\n		{ curr_lineno++; }
<BLOCK_COMMENT>"\*)"	{ BEGIN 0; }
<BLOCK_COMMENT><<EOF>>	{ cool_yylval.error_msg = "EOF in comment";
                          BEGIN 0; return (ERROR); }
<BLOCK_COMMENT>.		{}

 /*
  *  The multiple-character operators.
  */
{DARROW}		{ return (DARROW); }

 /*
  * Keywords are case-insensitive except for the values true and false,
  * which must begin with a lower-case letter.
  */
{CLASS}     { return (CLASS); }
{ELSE}     { return (ELSE); }
{FI}     { return (FI); }
{IF}     { return (IF); }
{IN}     { return (IN); }
{INHERITS}     { return (INHERITS); }
{LET}     { return (LET); }
{LOOP}     { return (LOOP); }
{POOL}     { return (POOL); }
{THEN}     { return (THEN); }
{WHILE}     { return (WHILE); }
{CASE}     { return (CASE); }
{ESAC}     { return (ESAC); }
{OF}     { return (OF); }
{NEW}     { return (NEW); }
{ISVOID}     { return (ISVOID); }
{NOT}     { return (NOT); }

{FALSE}   { cool_yylval.boolean = false;
            return BOOL_CONST; }
{TRUE}   { cool_yylval.boolean = true;
            return BOOL_CONST; }
{INT}     { cool_yylval.symbol = inttable.add_string(yytext); 
            return (INT_CONST); }
{TYPEID}  { cool_yylval.symbol = idtable.add_string(yytext); 
            return (TYPEID); }
{OBJECTID}  { cool_yylval.symbol = idtable.add_string(yytext); 
            return (OBJECTID); }
{ASSIGN}  { return (ASSIGN); }
{LE}      { return (LE); }

 /*
  *  The single-character operators.
  */

"{"			{ return '{'; }
"}"			{ return '}'; }
"("			{ return '('; }
")"			{ return ')'; }
"~"			{ return '~'; }
","			{ return ','; }
";"			{ return ';'; }
":"			{ return ':'; }
"+"			{ return '+'; }
"-"			{ return '-'; }
"*"			{ return '*'; }
"/"			{ return '/'; }
"."			{ return '.'; }
"<"			{ return '<'; }
"="			{ return '='; }
"@"			{ return '@'; }

 /*
  *  String constants (C syntax)
  *  Escape sequence \c is accepted for all characters c. Except for 
  *  \n \t \b \f, the result is c.
  *
  */

\"          { BEGIN(STRING); }
<STRING>\"  { BEGIN(INITIAL);
              string_buf_ptr = (char *) &string_buf;
              cool_yylval.symbol = stringtable.add_string(string_buf_ptr, str_len);
              str_len = 0;
              return (STR_CONST); }
<STRING><<EOF>> { cool_yylval.error_msg = "EOF in string constant"; 
                  return (ERROR); }
<STRING>\\\n  {}
<STRING>\n  { cool_yylval.error_msg = "Unterminated string constant"; 
              curr_lineno ++;
              BEGIN(INITIAL);
              return (ERROR); }
<STRING>\0  { cool_yylval.error_msg = "String contains null character"; 
              BEGIN(WAIT_STRING_END);
              return (ERROR); }
<STRING>\\b {
  if (str_len + 1 < MAX_STR_CONST) {
    string_buf[str_len ++] = '\b';
  }
  else {
    cool_yylval.error_msg = "String constant too long";
    str_len = 0;
    BEGIN(WAIT_STRING_END);
    return (ERROR); 
  }
}
<STRING>\\t {
  if (str_len + 1 < MAX_STR_CONST) {
    string_buf[str_len ++] = '\t';
  }
  else {
    cool_yylval.error_msg = "String constant too long";
    str_len = 0;
    BEGIN(WAIT_STRING_END);
    return (ERROR); 
  }
}
<STRING>\\n {
  if (str_len + 1 < MAX_STR_CONST) {
    string_buf[str_len ++] = '\n';
  }
  else {
    cool_yylval.error_msg = "String constant too long";
    str_len = 0;
    BEGIN(WAIT_STRING_END);
    return (ERROR); 
  }
}
<STRING>\\f {
  if (str_len + 1 < MAX_STR_CONST) {
    string_buf[str_len ++] = '\f';
  }
  else {
    cool_yylval.error_msg = "String constant too long";
    str_len = 0;
    BEGIN(WAIT_STRING_END);
    return (ERROR); 
  }
}
<STRING>\\0 {
  if (str_len + 1 < MAX_STR_CONST) {
    string_buf[str_len ++] = '\0';
  }
  else {
    cool_yylval.error_msg = "String constant too long";
    str_len = 0;
    BEGIN(WAIT_STRING_END);
    return (ERROR); 
  }
}
<STRING>\\[^\0] {
  if (str_len + 1 < MAX_STR_CONST) {
    string_buf[str_len ++] = yytext[1];
  }
  else {
    cool_yylval.error_msg = "String constant too long";
    str_len = 0;
    BEGIN(WAIT_STRING_END);
    return (ERROR); 
  }
}
<STRING>. {
  if (str_len + 1 < MAX_STR_CONST) {
    string_buf[str_len ++] = yytext[0];
  }
  else {
    cool_yylval.error_msg = "String constant too long";
    str_len = 0;
    BEGIN(WAIT_STRING_END);
    return (ERROR); 
  }
}

<WAIT_STRING_END>[\n|"] { BEGIN(INITIAL); 
                          curr_lineno ++;
                          str_len = 0; }
<WAIT_STRING_END>[^\n|"] {}

 /*
  * Error match
  */
.		{	cool_yylval.error_msg = yytext;
			return (ERROR);	}

%%
