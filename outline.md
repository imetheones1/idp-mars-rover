## steps

1. robot code scans enviroment with a lot of distance sensors
2. robot detects a distance that differs enough from heightmap within its path
3. robot waits until it gets a lot of data
4. robot writes the vertices to a file
5. robot runs triangulate.exe
    1. triangulate.exe reads vertices
    2. triangulate.exe creates triangle representation
    4. triangulate.exe smooths out the representation
    5. triangulate.exe writes new heightmap to a .ppn file
6. robot reads ppn file
7. robot calculates new path (maybe in seperate exe)
    1. Dijkstra's algorithm, using differences in height
8. repeat from 1 until made it to destination

## file formats

### vertices:
- 4 byte magic number
- uint64 vertex count
- every vertex
    - double for x
    - double for y
    - double for z

### heightmap

https://netpbm.sourceforge.net/doc/ppm.html

rgb together represent the height (0-16777216)