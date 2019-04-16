from osgeo import ogr
import sys

path = sys.argv[1]
driver = ogr.GetDriverByName('GPKG')
data_source = driver.Open(path, 0)
layer = data_source.GetLayer()

geometry = ogr.Geometry(ogr.wkbGeometryCollection)
for feature in layer:
    geometry.AddGeometry(feature.GetGeometryRef())

convex_hull = geometry.ConvexHull()
print(convex_hull.ExportToWkt())
