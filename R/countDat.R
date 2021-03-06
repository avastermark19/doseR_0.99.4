# clone
# clone2
# clone3

require(edgeR)

#' An S4 class that stores count data.
#' @slot data Contains counts data.
#' @slot RPKM Contains RPKM data.
#' @slot annotation Contains annotation column data.
#' @slot replicates Contains replicates data.
#' @slot rowObservables Contains rowObservables data, (including seglens).
#' @slot sampleObservables Contains sampleObservables data.
#' @slot orderings Contains orderings data.
#' @slot nullPosts Contains nullPosts data.
#' @slot cellObservables Contains cellObservables data.

setClass("countDat", representation(data = "array", RPKM = "array",
replicates = "factor", rowObservables = "list", sampleObservables =
"list", annotation = "data.frame" , orderings = "data.frame", nullPosts
= "matrix" , cellObservables = "list" ))

#' libsizes method for testClass
#'
#' @docType methods
#' @rdname libsizes-methods
#' @param x Value
#' @param value Value
#' @examples
#' libsizes

setGeneric("libsizes<-", function(x, value) standardGeneric("libsizes<-"))

#' libsizes method for testClass
#'
#' @docType methods
#' @rdname libsizes-methods
#' @keywords internal

setMethod("libsizes<-", signature = "countDat", function(x, value) {
x@sampleObservables$libsizes <- value
x
})

#' libsizes method for testClass
#'
#' @docType methods
#' @rdname libsizes-methods

setGeneric("libsizes", function(x) standardGeneric("libsizes"))

#' libsizes method for testClass
#'
#' @docType methods
#' @rdname libsizes-methods
#' @return libsize

setMethod("libsizes", signature = "countDat", function(x) {
x@sampleObservables$libsizes
})

###############################

#' getLibsizes method for count Dat class, derived from getLibsizes1
#' method (countData class).
#'
#' @docType methods
#' @rdname getLibsizes-methods
#' @usage getLibsizes2(cD, subset = NULL,
#' estimationType = c("quantile", "total",
#' "edgeR"),quantile = 0.75, ...)

#' @param cD A count Dat object.
#' @param subset Value
#' @param estimationType e.g. quantile, total, edgeR.
#' @param quantile A quantile, expressed as e.g. 0.75.
#' @param ... Passthrough arguments.

#' @examples
#' data(hmel.data.doser)
#' reps <- c("Male", "Male", "Male", "Female", "Female", "Female")
#' annotxn <- data.frame("Chromosome" = factor(hmel.dat$chromosome,
#' levels = 1:21))
#' hm.tr<-hmel.dat$trxLength
#' hm<-new("countDat",data=hmel.dat$readcounts,replicates=reps,
#' seglens=hm.tr,annotation=annotxn)
#' libsizes(hm) <- getLibsizes2(hm, estimationType = "total")
#' getLibsizes2(hm)
#'
#' @return Libsize value

'getLibsizes2'<- function(cD, subset = NULL,
estimationType = c("quantile", "total",   "edgeR"),
quantile = 0.75, ...) {
data<-cD@data
replicates <- cD@replicates
if(missing(subset)) subset <- NULL
if(is.null(subset)) subset <- seq_len(nrow(data))
estimationType = match.arg(estimationType)
if(is.na(estimationType)) stop("'estimationType' not known")
estLibs <- function(data, replicates)
{
libsizes <- switch(estimationType,
total = colSums(data[subset,,drop = FALSE], na.rm = TRUE),
quantile = apply(data[subset,, drop = FALSE], 2, function(z) {
x <- z[z > 0]
sum(x[x <= quantile(x, quantile, na.rm = TRUE)], na.rm = TRUE)
}),
edgeR = {
if(!("edgeR" %in% loadedNamespaces()))
requireNamespace("edgeR", quietly = TRUE)
d <- edgeR::DGEList(counts = data[subset,, drop = FALSE],
lib.size = colSums(data, na.rm = TRUE))
d <- edgeR::calcNormFactors(d, ...)
d$samples$norm.factors * d$samples$lib.size
})
names(libsizes) <- colnames(data)
libsizes
}
if(length(dim(data)) == 2) estLibsizes <- estLibs(data, replicates)
if(length(dim(data)) == 3) {
combData <- do.call("cbind", lapply(seq_len(dim(data)[3]),
function(kk) data[,,kk]))
combReps <- paste(as.character(rep(replicates, dim(data)[3])),
rep(c("a", "b"), each = ncol(data)), sep = "")
estLibsizes <- estLibs(combData, combReps)
estLibsizes <- do.call("cbind",
split(estLibsizes, cut(seq_len(length(estLibsizes)), breaks =
dim(data)[3], labels = FALSE)))
}

if(!missing(cD))
if(inherits(cD, what = "pairedData")) return(list(
estLibsizes[seq_len(ncol(cD))], estLibsizes[seq_len(ncol(cD)) + ncol(cD)]))

if(length(dim(data)) > 2) estLibsizes <- array(estLibsizes,
dim = dim(cD@data)[-1])

return(estLibsizes)
}

###############################

#' subsetting method for countDat class
#'
#' @docType methods
#' @rdname extract-methods
#' @param x countDat object Value
#' @param i first dimension, subsetting parameter
#' @param j second dimension, subsetting parameter
#' @param ... Passthrough arguments.
#' @param drop Value, Logical.
#' @return subsetted object

setMethod("[", "countDat", function(x, i, j, ..., drop = FALSE) {
if(missing(j)) {
j <- seq_len(ncol(x@data))
} else {
if(is.logical(j)) j <- which(j)
if(!all(seq_len(ncol(x@data)) %in% j))
{
replicates(x) <- as.character(x@replicates[j])
if(length(x@orderings) > 0)
{
warning("Selection of samples (columns) will invalidate
the values calculated in slot 'orderings', and so these will be discarded.")
x@orderings <- data.frame()
}

}
}

if(missing(i))
i <- seq_len(nrow(x@data))
if(is.logical(i)) i <- which(i)

if(nrow(x@data) > 0)
x@data <- .sliceArray2(list(i, j), x@data)
x@RPKM <- .sliceArray2(list(i, j), x@RPKM)

x@annotation <- x@annotation[i,, drop = FALSE]
if(nrow(x@orderings) > 0)
x@orderings <- x@orderings[i,, drop = FALSE]
if(length(x@nullPosts) > 0)
x@nullPosts <- x@nullPosts[i,,drop = FALSE]

x@rowObservables <- lapply(x@rowObservables,
function(z) .sliceArray2(list(i),z, drop = FALSE))
x@sampleObservables <- lapply(x@sampleObservables,
function(z) .sliceArray2(list(j), z, drop = FALSE))
x@cellObservables <- lapply(x@cellObservables,
function(z) .sliceArray2(list(i,j), z, drop = FALSE))

x
})

###############################

.sliceArray2 <- function(slices, array, drop = FALSE) {
if((is.vector(array) & sum(!vapply(slices, is.null, logical(1))) > 1)
|| (is.array(array) & length(slices) > length(dim(array))))
warning("dimensions of slice exceed dimensions of array")
sarray <-
abind::asub(array, slices, dims = seq_len(length(slices)), drop = drop)
sarray
}

#' replicates method for testClass
#'
#' @docType methods
#' @rdname replicates-methods
#' @param x Value
#' @param value Value
#'
#' @examples
#'
#' data(hmel.data.doser)
#' reps <- c("Male", "Male", "Male", "Female", "Female", "Female")
#' annotxn <- data.frame("Chromosome" = factor(hmel.dat$chromosome,
#' levels = 1:21))
#' hm.tr<-hmel.dat$trxLength
#' hm<-new("countDat",data=hmel.dat$readcounts,seglens=hm.tr,
#' annotation=annotxn)
#' replicates(hm) <- reps
#'
#' @return replicates populated object

setGeneric("replicates<-", function(x, value) standardGeneric("replicates<-"))

#' replicates method for testClass
#'
#' @docType methods
#' @rdname replicates-methods
#' @keywords internal

setMethod("replicates<-", signature = "countDat", function(x, value) {
x@replicates <- as.factor(value)
x
})

######################

setMethod("show", "countDat", function(object) {
cat(paste('An object x of class "', class(object), '"\n', sep = ""))
cat(paste(nrow(object), 'rows and', ncol(object), 'columns\n'))
cat('\nSlot "replicates"\n')
cat(as.character(object@replicates))
cat('\nSlot "data":\n')
if(nrow(object@data) > 5)
{
print(.showData(.sliceArray2(list(seq_len(5)), object@data)), quote=FALSE)
cat(paste(nrow(object) - 5), "more rows...\n")
} else print(.showData(object@data))
cat('\nSlot "RPKM":\n')
if(nrow(object@RPKM) > 5)
{
print(.showData(.sliceArray2(list(seq_len(5)), object@RPKM)), quote=FALSE)
cat(paste(nrow(object) - 5), "more rows...\n")
} else print(.showData(object@RPKM))
cat('\nSlot "annotation":\n')
if(nrow(object@annotation) > 5 & ncol(object@annotation) > 0)
{
print(object@annotation[seq_len(5),])
cat(paste(nrow(object) - 5), "more rows...\n")
} else print(object@annotation)
})

##################

.showData <- function(data)
{
if(is.vector(data) || length(dim(data)) <= 2) return(data)
dimsep <- c(":", "|")
dimlen <- length(dim(data))
if(length(dim(data)) > 4)
dimsep <- c(dimsep, vapply(2:(dimlen - 2), function(x) paste(rep("|", x),
character(1), collapse = "")))
dimsep <- c("", dimsep)
dimsep <- dimsep[seq_len(dimlen - 1)]

dimsep <- rev(dimsep)
dimdat <- data

pasteDat <- function(x, dimnum) {
if(length(dim(x)) > 2) {
padat <- t(apply(x, 1, function(xx) paste(
pasteDat(xx, dimnum = dimnum + 1), collapse = dimsep[dimnum])))
} else {
padat <- (apply(x, 1, function(z) paste(z, collapse = ":")))
}
return(padat)
}
pastemat <- t(apply(data, 1, pasteDat, dimnum = 1))
pastemat
}

######################

setGeneric(".seglens<-", function(x, value) standardGeneric(".seglens<-"))
setMethod(".seglens<-", signature = "countDat", function(x, value) {
if(!is.numeric(value)) stop("All members of seglens for a
countData object must be numeric.")

if(inherits(value, "numeric")) {
if(length(value) != ncol(x)) stop("Length of seglens must
be identical to the number of columns of the countDat object.")
value <- matrix(value, ncol = 1)
} else if(is.array(value))
if(any(dim(x@data)[-1] != dim(value))) stop("Dimension of seglens
must be identical to the dimension of the countData object
(after dropping the first dimension).")

if(any(value <= 0)) stop("Library sizes less than or equal
to zero make no sense to me!")
x@rowObservables$seglens <- value
x
})

setGeneric(".seglens", function(x) standardGeneric(".seglens"))
setMethod(".seglens", signature = "countDat", function(x) {
if(".seglens" %in% names(x@rowObservables)) return(x@rowObservables$seglens)
if(".seglens" %in% names(x@cellObservables)) return(x@cellObservables$seglens)
return(matrix(rep(1, nrow(x)), ncol = 1))
})

#####################

setMethod("initialize", "countDat", function(.Object, ..., data,
replicates, libsizes, seglens) {
.Object <- callNextMethod(.Object, ...)
if(!missing(data) && is.array(data)) .Object@data <- data
if(!missing(data) && is.list(data)) .Object@data <-
array(do.call("c", data), c(dim(data[[1]]), length(data)))
if(missing(replicates)) replicates <- .Object@replicates
.Object@replicates <- as.factor(replicates)
if(length(dim(.Object@data)) == 1) .Object@data <-
array(.Object@data, dim = c(dim(.Object@data),
max(c(0, length(replicates), length(.Object@replicates)))))
if(length(colnames(.Object@data)) == 0) colnames(.Object@data) <-
make.unique(c(as.character(unique(.Object@replicates)),
as.character(.Object@replicates)))[-(seq_len(
length(unique(.Object@replicates))))]
if(nrow(.Object@annotation) > 0 & nrow(.Object@annotation) !=
nrow(.Object@data))
warning("Number of rows of '@annotation' slot not same as '@data' slot.")
if(length(.Object@nullPosts) != 0) {
if(nrow(.Object@nullPosts) != nrow(.Object@data)
& nrow((.Object@nullPosts) != 0))
stop("Number of rows in '@data' slot must
equal number of rows of '@nullPosts' slot.")
} else nullPosts <- matrix(ncol = 0, nrow = nrow(.Object@data))
if(!missing(seglens))
{
if(is.vector(seglens)) {
if(length(seglens) != nrow(.Object@data)) stop("If 'seglens'
specified, and is a vector, the length of this variable must
equal the number of rows of '@data' slot.")
.Object@rowObservables$seglens <- seglens
}
}
if(length(.Object@rowObservables) > 0) {
notRow <- vapply(.Object@rowObservables, length,
numeric(1)) != nrow(.Object@data)
if(any(notRow)) stop(paste("The following '@rowObservables'
elements have an incorrect length:", paste(names(notRow)[notRow],
collapse = ",")))
}
if(length(replicates) != 0 && length(replicates) != ncol(.Object@data))
stop("The length of the '@replicates' slot must equal number of
columns of '@data' slot.")
.Object
})

##########################

#' replicates method for testClass
#'
#' @docType methods
#' @rdname nrow-methods
#' @param x Value
#' @return nrow(x@data)
#' @keywords internal

setMethod("nrow", "countDat", function(x) {
nrow(x@data)
})

##########################

#' replicates method for testClass
#'
#' @docType methods
#' @rdname ncol-methods
#' @param x Value
#' @return length(x@replicates)
#' @keywords internal

setMethod("ncol", "countDat", function(x) {
length(x@replicates)
})

##########################

#' rpkm method for testClass
#'
#' @docType methods
#' @rdname rpkm-methods
#' @param x Value
#' @param value Value
#' @examples
#'
#' data(hmel.data.doser)
#' reps <- c("Male", "Male", "Male", "Female", "Female", "Female")
#' annotxn <- data.frame("Chromosome" =
#' factor(hmel.dat$chromosome, levels = 1:21))
#' hm.tr<-hmel.dat$trxLength
#' hm<-new("countDat",data=hmel.dat$readcounts,seglens=hm.tr,
#' annotation=annotxn)

setGeneric("rpkm<-", function(x, value) standardGeneric("rpkm<-"))

#' rpkm method for testClass
#'
#' @docType methods
#' @rdname rpkm-methods
#' @param x Value
#' @param value Value
#' @keywords internal

setMethod("rpkm<-", signature = "countDat", function(x, value) {
x@RPKM <- value
x
})

##########################

#' rpkm method for testClass
#'
#' @docType methods
#' @rdname rpkm-methods
#' @param x Value
#' @return x@RPKM
#' @examples
#'
#' data(hmel.data.doser)
#' reps <- c("Male", "Male", "Male", "Female", "Female", "Female")
#' annotxn <- data.frame("Chromosome" = factor(hmel.dat$chromosome,
#' levels = 1:21))
#' hm.tr<-hmel.dat$trxLength
#' hm<-new("countDat",data=hmel.dat$readcounts,seglens=hm.tr,
#' annotation=annotxn)

setGeneric("rpkm", function(x) standardGeneric("rpkm"))

#' rpkm method for testClass
#'
#' @docType methods
#' @rdname rpkm-methods
#' @param x Value
#' @return x@RPKM
#' @keywords internal

setMethod("rpkm", signature = "countDat", function(x) {
x@RPKM
})

##########################

#' replicates method for testClass
#'
#' @docType methods
#' @rdname replicates-methods
#' @param x Value
#' @return x@replicates
#' @examples
#'
#' data(hmel.data.doser)
#' reps <- c("Male", "Male", "Male", "Female", "Female", "Female")
#' annotxn <- data.frame("Chromosome" = factor(hmel.dat$chromosome,
#' levels = 1:21))
#' hm.tr<-hmel.dat$trxLength
#' hm<-new("countDat",data=hmel.dat$readcounts,seglens=hm.tr,
#' annotation=annotxn)

setGeneric("replicates", function(x) standardGeneric("replicates"))

#' replicates method for testClass
#'
#' @docType methods
#' @rdname replicates-methods
#' @param x Value
#' @return x@replicates
#' @keywords internal

setMethod("replicates", signature = "countDat", function(x) {
x@replicates
})
