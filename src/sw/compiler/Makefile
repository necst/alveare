NAME = compiler
CC = gcc
CCFLAGS = -w
YACC = bison
FLEX = flex
LIBRARIES = ast.c
HEADERS = ast.h
UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Linux)
	CCFLAGS += -lfl
endif
ifeq ($(UNAME_S),Darwin)
	CCFLAGS += -ll
endif	

all: $(NAME)

$(YACC): $(NAME).y
	$(YACC) -d $(NAME).y -v		

$(FLEX): $(NAME).lex
	$(FLEX) -o $(NAME).yy.c $(NAME).lex 

$(NAME): $(FLEX) $(YACC) $(HEADERS) $(LIBRARIES)

	$(CC) -o $@ $(NAME).yy.c $(NAME).tab.c $(LIBRARIES) $(CCFLAGS)

clean:
	rm -f *.yy.c *.tab.c *.tab.h *.output
	rm -f $(NAME)
