; See Sentaurus Structure Editor User Guide.

(sde:clear)

; ------------------------------------------------------------------------

(display "  Reading in epi layer system") (newline)
(sdeepi:publish-global-vars #t)
; P.584. This Scheme extension defines the global and layer variables of the sdeepi Scheme extensions as global Scheme variables.

(sdeepi:create-layerstack "@epicsv@")
; P.583. This Scheme extension creates a planar layer stack structure from the CSV input data.

(sdeepi:tcl "@epicsv@" "@epitcl@")
; P.586. This Scheme extension creates a Tcl script that contains all layer stack–specific data from the CSV input file in the form of Tcl variables.

; ------------------------------------------------------------------------

(display "  Geometric variables") (newline)
(define wtot Xmax)

; ------------------------------------------------------------------------

(display "Add Contacts") (newline)

(display "  top contact") (newline)

(sdegeo:define-contact-set "cathode" 4  (color:rgb 1 0 0 ) "##" )
; P.634. Create a contact region called "cathode". Set the thickness to be 4, color to be red, face pattern to be "##".

(sdegeo:set-current-contact-set "cathode")
; P.691. This Scheme extension sets the name of the current (active) contact to the specified contact set.

(sdegeo:set-contact (find-edge-id (position (/ Xmax 2) 0 0)) "cathode")
; P.685, P384. Set the contact to that position.(I guess.)


(display "  bottom contact") (newline)
(sdegeo:define-contact-set "anode" 4  (color:rgb 1 0 0 ) "##" )
(sdegeo:set-current-contact-set "anode")
(sdegeo:set-contact (find-edge-id (position (/ wtot 2) Ymax 0)) "anode")
(sde:refresh)
; Similar as above.

; ------------------------------------------------------------------------

;;(display "Add Refinements") (newline)
;(display "  optical refinement") (newline)

;;(sdedr:define-refeval-window "optics" "Rectangle" (position 0 0 0) (position wtot Ymax 0) )
; P.553. This Scheme extension defines a geometric region that can be used as a Reference/Evaluation Window.
  
;;(sdedr:define-refinement-size "optics" 10 1 0.01 0.001)
; P.560. [Syntax] (sdedr:define-refinement-size definition-name max-x [max-y] [max-z] min-x [min-y] [min-z])

;;(sdedr:define-refinement-placement "opitcs" "opitcs" "opitcs" )

; ------------------------------------------------------------------------

(display "saving & meshing") (newline)

(sde:build-mesh "n@node@_msh")
; P.437. This Scheme extension generates a 2D or 3D TDR tessellated boundary output and a mesh command file, and calls Sentaurus Mesh using a system command call.

(display "... CST world 2%") (newline)