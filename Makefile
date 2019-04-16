entwine/%: %.laz
	@mkdir -p $(dir $@)
	DYLD_LIBRARY_PATH=~/local/lib entwine build -i $< -o $@ --srs "" --cacheSize 512

build/density/%.gpkg: laz/%.laz
	@mkdir -p $(dir $@)
	pdal density -i $< -o $@ -f GPKG --edge_length=10 --threshold=10

build/boundary/%.wkt: build/density/%.gpkg scripts/convex_hull.py
	@mkdir -p $(dir $@)
	python3 $(word 2,$^) $< > $@

build/snow-free/for-%/2016-09-28-SnowEx-SBB.laz: laz/2016-09-28-SnowEx-SBB.laz build/boundary/%-SnowEx-SBB.wkt pipelines/snow-free.json
	@mkdir -p $(dir $@)
	pdal pipeline -v 8 $(word 3,$^) \
		--readers.las.filename=$< \
		--filters.crop.polygon="$(shell cat $(word 2,$^))" \
		--writers.las.filename=$@
.PRECIOUS: build/snow-free/for-%/2016-09-28-SnowEx-SBB.laz

build/snow-on/%.laz: laz/%.laz build/boundary/2016-09-28-SnowEx-SBB.wkt pipelines/snow-on.json
	@mkdir -p $(dir $@)
	pdal pipeline -v 8 $(word 3,$^) \
		--readers.las.filename=$< \
		--filters.crop.polygon="$(shell cat $(word 2,$^))" \
		--writers.las.filename=$@
.PRECIOUS: build/snow-free/for-%/2016-09-28-SnowEx-SBB.laz

build/dhs/2017-02-09-SnowEx-SBB.laz: laz/2017-02-09-SnowEx-SBB.laz build/boundary/2017-02-21-SnowEx-SBB.wkt pipelines/snow-on.json
	@mkdir -p $(dir $@)
	pdal pipeline -v 8 $(word 3,$^) \
		--readers.las.filename=$< \
		--filters.crop.polygon="$(shell cat $(word 2,$^))" \
		--writers.las.filename=$@

build/dhs/2017-02-21-SnowEx-SBB.laz: laz/2017-02-21-SnowEx-SBB.laz build/boundary/2017-02-09-SnowEx-SBB.wkt pipelines/snow-on.json
	@mkdir -p $(dir $@)
	pdal pipeline -v 8 $(word 3,$^) \
		--readers.las.filename=$< \
		--filters.crop.polygon="$(shell cat $(word 2,$^))" \
		--writers.las.filename=$@

build/hag/%-SnowEx-SBB.laz: build/snow-on/%-SnowEx-SBB.laz build/snow-free/for-%/2016-09-28-SnowEx-SBB.laz pipelines/hag.json
	@mkdir -p $(dir $@)
	pdal pipeline -v 8 $(word 3,$^) \
		--stage.snowfree.filename=$(word 2,$^) \
		--stage.snowon.filename=$(word 1,$^) \
		--writers.las.filename=$@
.PRECIOUS: build/hag/%-SnowEx-SBB.laz

build/hag/2017-02-09-to-2017-02-21-SnowEx-SBB.laz: build/dhs/2017-02-21-SnowEx-SBB.laz build/dhs/2017-02-09-SnowEx-SBB.laz pipelines/hag.json
	@mkdir -p $(dir $@)
	pdal pipeline -v 8 $(word 3,$^) \
		--stage.snowfree.filename=$(word 2,$^) \
		--stage.snowon.filename=$(word 1,$^) \
		--filters.colorinterp.minimum=-0.5 \
		--filters.colorinterp.maximum=0.5 \
		--filters.colorinterp.ramp=pestel_shades \
		--writers.las.filename=$@

build/raster/%.tif: laz/%.laz pipelines/raster.json
	@mkdir -p $(dir $@)
	pdal pipeline -v 8 $(word 2,$^) \
		--readers.las.filename=$< \
		--writers.gdal.filename=$@

build/colorization/%.laz: laz/%.laz build/raster/2016-09-28-SnowEx-SBB.tif pipelines/colorization.json
	@mkdir -p $(dir $@)
	pdal pipeline -v 8 $(word 3,$^) \
		--readers.las.filename=$< \
		--filters.colorization.raster=$(word 2,$^) \
		--writers.las.filename=$@

build/hag-improved/%-SnowEx-SBB.laz: build/snow-on/%-SnowEx-SBB.laz build/snow-free/for-%/2016-09-28-SnowEx-SBB.laz pipelines/hag.json
	@mkdir -p $(dir $@)
	pdal pipeline -v 8 $(word 3,$^) \
		--stage.snowfree.filename=$(word 2,$^) \
		--stage.snowon.filename=$(word 1,$^) \
		--filters.hag.count=5 \
		--filters.hag.allow_extrapolation=false \
		--filters.hag.max_distance=2 \
		--writers.las.filename=$@
.PRECIOUS: build/hag/%-SnowEx-SBB.laz

build/hag-improved/2017-02-09-to-2017-02-21-SnowEx-SBB.laz: build/dhs/2017-02-21-SnowEx-SBB.laz build/dhs/2017-02-09-SnowEx-SBB.laz pipelines/hag.json
	@mkdir -p $(dir $@)
	pdal pipeline -v 8 $(word 3,$^) \
		--stage.snowfree.filename=$(word 2,$^) \
		--stage.snowon.filename=$(word 1,$^) \
		--filters.hag.count=5 \
		--filters.hag.allow_extrapolation=false \
		--filters.hag.max_distance=2 \
		--filters.colorinterp.minimum=-0.2 \
		--filters.colorinterp.maximum=0.2 \
		--filters.colorinterp.ramp=pestel_shades \
		--writers.las.filename=$@

