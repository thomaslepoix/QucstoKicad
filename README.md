# QucstoKicad

- **Qucs  :** http://qucs.sourceforge.net/
- **KiCad :** http://kicad-pcb.org/

Qucs doesn't have any layout editor so here is a script to export HF components (microstrip or coplanar) to KiCad - PcbNew.

It currently suppports only microstrip elements : `MLIN`, `MTEE`

- A first version QtK.sh exports microstrip elements to pad shapes randomly placed that need to be placed manualy.
- A second version currently in dev branch will autoroute the layout and place shapes like in the Qucs shematic.

## Usage

```
./QtK.sh <Qucs/schematic.sch> <KiCad/layout.kicad_pcb>
```
