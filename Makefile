FORMS=\
 appmenu.42f \
 appmenu_test.42f

PROGMOD=\
 libappmenu.42m \
 appmenu_test.42m

all: $(PROGMOD) $(FORMS)

run: all
	fglrun appmenu_test

%.42f: %.per
	fglform -M $<

%.42m: %.4gl
	fglcomp -Wall -M $<

clean::
	rm -f *.42?
