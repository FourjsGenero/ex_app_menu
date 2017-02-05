FORMS=\
 appmenu.42f \
 appmenu_test.42f

PROGMOD=\
 libappmenu.42m \
 appmenu_test.42m

all: $(PROGMOD) $(FORMS)

%.42f: %.per
	fglform -M $<

%.42m: %.4gl
	fglcomp -M $<

clean::
	rm -f *.42?