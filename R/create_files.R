#' ==================================================================================
#' Create Radimoetric and Topographic corrected files from Landsat 8 OLI
#' Paulo E. Cardoso 16-09-2014
#' Version v8
#' R version 3.0.2 rgdal_0.8-16  raster_2.2-16 sp_1.0-14
#'# Utiliza dados de Digital Elevation Model (DEM) Aster (30m) ou SRTM (90m)
#'## ASTER GDEM: Usar o Tile ASTGTM2_S12E014
#'## SRTM v4.1: usar o Tile srtm_39_15
#' ==================================================================================

#' TODO =============================================================================
#'# Incorporate Image texture from glcm package
#'# http://azvoleff.com/articles/glcm-0-2-released/
#' Studyteamlucc package from github repository https://github.com/azvoleff/teamlucc
#' Surface reflectances with DOS atmospheric correction
#'# http://grass.osgeo.org/grass65/manuals/i.landsat.toar.html
#' ==================================================================================

#' Packages necessarios
kpacks <- c("raster", "sp", "rgdal", 'rgeos', 'lattice')
new.packs <- kpacks[!(kpacks %in% installed.packages()[ ,"Package"])]
if(length(new.packs)) install.packages(new.packs)
lapply(kpacks, require, character.only=T)
remove(kpacks, new.packs)

sessionInfo() # basics of used session
# R version 3.1.0 (2014-04-10) -- "Spring Dance"
# rgeos_0.3-6  rgdal_0.8-16 raster_2.3-0 sp_1.0-15

#' Folders --------------------------------------------------------------------------
#'# Adjust for Local work paths
dir.work <- 'S:/Raster/Landsat' # Alterar para Disco Local
dir.rst   <- 'rst' # Criar no dir.work do disco local
dir.tif <- 'tif'  # Criar no dir.work do disco local
dir.userdem <- '..' # Alterar para o Local Folder
### Data das Landsat. Define as many as necesary.
### dir.fun must be changed for all analysis

#' Chacheu 2014 e 2013-12-29
dir.landsat <- 'LC82040522014142LGN00/qgis' # Folder with Landast 8 TIF files
dir.landsat <- 'LC82040522013363LGN00' # 2013-12-29
dir.shp <- 'S:/Bissau/Cacheu/vetor'

# Bijagos 2014-03-19
dir.landsat <- 'LC82040522014078LGN00/qgis/dos1' # Folder with Landast 8 TIF files
dir.shp <- 'S:/Bissau/vetor'
dir.fun <- dir.landsat # Change here to perform all subsequent analysis!

# Bijagos 2013-11-27 LC82040522013331LGN0
dir.landsat2 <- 'LC82040522013331LGN00/qgis' # 2013-12-29

#' Satelite parameters and data ----------------------------------------------------
## All subsequente analysis is for a single date
dir.fun <- dir.landsat # Change here to perform all subsequent analysis!
dir.fun <- dir.landsat2 # Change here to perform all subsequent analysis!

#'# Create  folders for raster and images outputs
dir.create(file.path(dir.work, dir.fun, dir.tif))
dir.create(file.path(dir.work, dir.fun, dir.rst))

#'# Saving and Loading R data session ------------------------------------------------
save.image(file.path(dir.work, dir.fun, paste0(dir.fun,'.RData')))
load(file.path(dir.work, dir.fun, paste0(dir.fun,'.RData'))

#'# Landsat 8 Scene Metadata: MTL File -----------------------------------------------
#'## Metadata file contains scene acquisition details and correction parameters
#'## Unzip the MTL file from landsat L8 zipped .tar file
#'## MTL must be with Landsat TIF files, at the exact same folder
mtl <- read.delim(file.path(dir.work, dir.fun,  
                            grep('_MTL.txt',
                                 list.files(file.path(dir.work, dir.fun),
                                            all.files = F),
                                 ignore.case = TRUE, value = TRUE)),
                  sep = '=', stringsAsFactors = F)
mtl[grep("DATE_ACQUIRED", mtl$GROUP), 2]
mtl[grep("LANDSAT_SCENE_ID", mtl$GROUP), 2]

#' Local parameters -----------------------------------------------------------------
#'# Projections
#'# Pick the EPSG code for projection parameters definition.
#'# oficial repository of EPSG at http://www.epsg-registry.org/
#'# other source of info at http://spatialreference.org/
p.utm28n <- CRS("+init=epsg:32628") # UTM 28N Landsat Images (Guiné)
p.utm28s <- CRS("+init=epsg:32728") # UTM 28N Landsat Images (Guiné)
p.utm33n <- CRS("+init=epsg:32633") # UTM 33N Landsat Images
p.utm33s <- CRS("+init=epsg:32733") # UTM 33S Landsat Images
p.wgs84 <- CRS("+init=epsg:4326") # WGS84 Long Lat

#' Study site frame extent ---------------------------------------------------------
#'# Create rectangular area for image cropping
#'# A projected spatialpolydf will be created and projected to utm33N
ae <- readOGR(dsn = file.path(dir.shp), layer = 'Cacheu_gadm')
ae <- readOGR(dsn = file.path(dir.shp), layer = 'mangal_cacheu')
ae <- readOGR(dsn = file.path(dir.shp), layer = 'GNB_Bijagos200mUTM28S')
proj4string(ae) <- p.utm28s
#proj4string(ae) <- p.wgs84 # Asign projection
#if(!is.projected(ae)) ae <- spTransform(ae, p.utm28n)
#'# if UTM projection is South
ae <- spTransform(ae, p.utm28n) 
#'# Create Extent from ae or provide another Shape for a different extent 
roi <- extent(ae) # a rectangular area covering ae polygon extent

<<<<<<< HEAD
#'# CREATE MASK ---------------------------------------------------------------------
=======
<<<<<<< HEAD
#'--- TEST ONLY --------------------------------------------------------------------
#'# Smaller subarea of ROI for test purposes --------
=======
#'---------------TEST ONLY ----------------------------
#'## Smaller subarea of ROI for test purposes ---------
>>>>>>> e37a834a72ab08633877dd5970fe9368964fb982
roi2 <- as(roi - c(3000, 7000), 'SpatialPolygons')
proj4string(roi2) <- p.utm33n
ae2 <- gIntersection(ae, roi2, byid = TRUE)
plot(roi2, axes = T);plot(ae2, add = T)
#'# Morro Moco Study Area --
roimoco <- extent(c(15.15, 15.18, -12.45, -12.40))
moco <- as(roimoco, 'SpatialPolygons')
proj4string(moco) <- p.wgs84 # Asign projection WGS84
mocoutm <- spTransform(moco, p.utm33n)
#'----------------------------------------------------------------------------------

#' Build Mask Raster used to crop images to ROI area -------------------------------
#'# Mask file must be created. It is a mandatory step of the process
#'# considering the way it was setup
#'## 1st: Read a single Band to get the desired extent based on satellite images
#'## Change function arguments for the ROI and polygon to apply mask
f.CreateRoiMask <- function(x = x, roi = roi2, maskpoly = ae2){
  x <- grep(".tif$", list.files(file.path(dir.work, dir.fun), all.files = F),
            ignore.case = TRUE, value = TRUE)[1] 
  i.band <- raster(file.path(dir.work, dir.fun, x),
                   package = "raster")
  ##dataType(band) # Must be INT2U for Landsat 8. Range of Values: 0 to 65534
  stopifnot(!is.na(i.band@crs)) # Check projection
  ## Create Extent object from ae shapefile
  if(is.null(roi)){
    i.roi <- extent(ae2)
  } else i.roi <- extent(roi)
  # Crop Landsat Scene to AE extent
  i.bandae <- crop(i.band, i.roi) # Crop band to AE Extent
  ## 2nd: Create the Mask raster to the croped band extent
  ae.r <- i.bandae # Raster AE: resolucao 30m (Landast)
  ae.r[] <- 1 # Defalt value
  ## Overlay AE poly to AE Extent raster
  ## Mask will have 1 and NA values
  msk.ae <- mask(ae.r, maskpoly, updatevalue=NA)
  #dataType(mask_ae) <- "INT1U" 
  ## Evaluate rasters
  stopifnot(compareRaster(msk.ae, i.bandae)) 
  msk.ae
}

#'## Run the function
>>>>>>> 62725d2043b482c4d0c87a2d510173e656e22c70
#'## Mask will be a c(1, NA) rasterLayer
if(exists('mask_ae')) remove(mask_ae)
mask_ae <- f.CreateRoiMask(roi = roi, maskpoly = ae)

plot(mask_ae); summary(mask_ae)
writeRaster(mask_ae, filename = file.path(dir.work, dir.landsat, dir.tif,
                                          "mask_ae.asc"),
            overwrite = T)

#'# CREATE UNCORRECTED TOA REFLECTANCE BANDS, UNMASKED -------------------------------
stk_toar <- f.ToarL8(roi = roi)
stk_toardez2013 <- f.ToarL8(roi = roi)
plot(stk_toar)

#'# CREATE ROI with DOS1 CORRECTED RELECTANCES : As Obtained from QGIS Plugin
stk_dos1 <- f.stkDOS1(roi = roi)

#'# APPLY MASK TO STACK --------------------------------------------------------------
stktoar_msk <- f.applmask(stk = stk_dos1, mask = mask_ae)
#stktoar_mskdez2013 <- f.applmask(stk = stk_toardez2013, mask = mask_ae)
plot(stktoar_msk)

#'# Functions for Radiometric and Topographic calibration Landsat 8 ------------------
### According to http://www.gisagmaps.com/landsat-8-atco-guide/, DOS may perform
#### better under some circumnstances.
#### More info at:
#### http://landsat.usgs.gov/Landsat8_Using_Product.php
#### http://landsat.usgs.gov/L8_band_combos.php : Band References
#### ESUN and OLI: http://landsat.usgs.gov/ESUN.php
## DN to uncorrected TOA reflectance: planetary reflectance
## Define the parent frame from where objects will be called


#' Topographic correction -----------------------------------------------------------
# Lu et al 2008. Pixel-based Minnaert Correction..
# Vanonckelen et al 2013. The effect of atmospheric and topographic...
f.TopoCor <- function(x = x, i = i, method = 'minnaert',
                      slope, aspect, il.ae, sun.e, sun.z, sun.a) {
  message('Images will be corrected to planetary Top of Atmosphere Reflectances')
  METHODS <- c('none', 'cosine', 'ccorrection', 'minnaert')
  method <- pmatch(method, METHODS)
  itoa <- f.ToarL8(x = x,  i = i)
  if(method == 1){
    message('Message: No Topo correction will be applied')
    xout <- itoa
  } else if(method == 2){
    message('Message: cosine will be applied')
    xout <- itoa * (cos(sun.z)/il.ae)
  } else if (method == 3) {
    message('Message: c_correction will be applied')
    subspl <- sample(1:ncell(itoa), floor(ncell(itoa)*0.50), rep = F)
    band.lm <- lm(as.vector(itoa[subspl]) ~ as.vector(il.ae[subspl]))$coefficients
    #band.lm <- lm(as.vector(i.toa) ~ as.vector(il.ae))$coefficients
    C <- band.lm[1]/band.lm[2]
    xout <- itoa * (cos(sun.z) + C)/(il.ae + C)
  } else if(method == 4) {
    message('Message: Minnaert will be applied')
    targetslope <- atan(0.05)
    if (all(itoa[slope >= targetslope] < 0, na.rm = TRUE)) {
      K <- 1
    } else {
      K <- data.frame(y = as.vector(itoa[slope >= targetslope]), 
                      x = as.vector(il.ae[slope >= targetslope])/cos(sun.z))
      K <- K[!apply(K, 1, function(x) any(is.na(x))), ]
      K <- K[K$x > 0, ]
      K <- K[K$y > 0, ]
      K <- lm(log10(K$y) ~ log10(K$x))
      K <- coefficients(K)[[2]]
      if (K > 1) 
        K <- 1
      if (K < 0) 
        K <- 0
    }
    xout <-(itoa * cos(sun.z))/((il.ae * cos(sun.z))^K)
  }
  xout
}

#'# for TEST purpose only. Do not run outside main function
ltest <- f.TopoCor(x = i.crop, i = 1, method = 'minnaert') # Test only

# ----------------------------------------------------------------------------------
# Main Function to create radiometric corrected Files ------------------------------
# For original Landsat Product only
# Function arguments:
## write: (TRUE/FALSE): Export RST raster file
## demcorr: ('none', cosine, ccorrection, minnaert). Topographic correction algorithm 
## mask: (TRUE/FALSE) Aply a mask to the ROI extent. Mask will be a polygon.
### Resulting in a 1/NA rasterLayer.
## dem: rasterStack with DEM, slope and aspect layers.

f.l8data <- function(write = F, demcorr = 'none', mask = T,
                     dem = dem.ae, wrformat = 'RST') {
  i.allfiles <- list.files(file.path(dir.work, dir.fun), all.files = F)
  # List of TIF files at dir.fun folder
  i.listtif <- grep(".tif$", i.allfiles, ignore.case = TRUE, value = TRUE) 
  bands <- as.numeric(substr(i.listtif, (nchar(i.listtif) - 4),
                             (nchar(i.listtif) - 4)))
  i.stk.toar <- stack()
  #i.stk.toart <- stack() # topocorr
  i.lstk <- list()
  # SUN Parameters ---
  ## Sun elev in radians
  sun.e <- as.numeric(mtl[grep("SUN_ELEVATION", mtl$GROUP), 2]) * (pi/180) 
  ## Sun Zenit in radians
  sun.z <- (90 - as.numeric(mtl[grep("SUN_ELEVATION", mtl$GROUP), 2])) * (pi/180)
  ## Sun Azimuth
  sun.a <- as.numeric(mtl[grep("SUN_AZIMUTH", mtl$GROUP), 2])* (pi/180)
  # DEM Parameters for Topo Correction ---
  #  if(topocor != 'none'){
  il.epsilon <- 1e-06
  # DEM slope and Aspect
  slope <- dem[['slope']]
  aspect <- dem[['aspect']]
  il.ae <- cos(slope) * cos(sun.z) + sin(slope) *
    sin(sun.z) * cos(sun.a - aspect)
  # stopifnot(min(getValues(il.ae), na.rm = T) >= 0)
  il.ae[il.ae <= 0] <- il.epsilon
  #  }
  for (i in 1:length(bands)) {
    message(bands[i])
    # Name
    i.fname <- paste0('b',bands[i],'_ae')
    # Read Geotif raster
    i.tmp <- raster(file.path(dir.work, dir.fun, i.listtif[i]),
                    package = "raster", varname = fname, dataType = 'FLT4S')
    # Crop and apply mask
    i.crop <- crop(i.tmp, extent(mask.ae))
    # uncorrected TOA Reflectance with Topographic correction with mask overlay
    i.toar <- f.TopoCor(x = i.crop, i = bands[i], method = demcorr,
                        slope, aspect, il.ae, sun.e, sun.z, sun.a)
    if(mask == T) {
      i.toar <- i.toar * mask.ae
    } else i.toar <- i.toar
    i.toar@data@names <- i.fname  # Add band name  
    # Create Stack
    if(i < 8) {
      i.stk.toar <- addLayer(i.stk.toar, i.toar)
      #i.stk.toart <- addLayer(i.stk.toart, i.toartmsk)
    }
    # Write IDRISI raster group rgf for uncorrected TOA Reflectance
    if(write == T) {
      dire <- file.path(dir.work, dir.fun, dir.tif)
      stopifnot(file_test("-d", dire))
      ## gdal
      ##writeGDAL(as(i.l8, "SpatialGridDataFrame"),
      ##fname = "D:\\idri.rst", drivername = "RST") 
      message(wrformat, 'raster will be created for ', i.fname, ' at: ',
              file.path(dir.work, dir.fun, dir.tif))
      writeRaster(i.toar, filename = file.path(dir.work, dir.fun, dir.tif,
                                               i.fname),
                  datatype = 'FLT4S', format = wrformat, #'RST',
                  overwrite = TRUE)
      fileConn <- file(file.path(dir.work, dir.fun, dir.tif, "ae_toar.rgf"))
      writeLines(c(length(i.listtif),
                   paste0('b', bands, '_ae')),
                 fileConn)
      close(fileConn)
    }
  }
  i.stk.toar
}

#' RUN function to get rasterStack with processed bands -----------------------------
#' write = F, demcorr = 'none', mask = T, dem = dem.ae, wrformat = 'RST'
l8files <- f.l8data(write = F, wrformat = 'ENVI', demcorr = 'none', mask = T)

# Export rasterStack to a BSQ TIF File
writeRaster(l8files, filename=file.path(dir.work, dir.landsat, dir.tif,
                                        "stack201400606.tif"),
            options="INTERLEAVE=BAND", overwrite=TRUE)
# Plot it
plotRGB(l8files, 6, 4, 2, stretch = 'hist')
