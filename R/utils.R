
# environment that contains global variables
INDEX_ENV = new.env()

INDEX_ENV$I_FIGURE = 0
INDEX_ENV$I_HEATMAP = 0
INDEX_ENV$I_ANNOTATION = 0
INDEX_ENV$I_ROW_ANNOTATION = 0
INDEX_ENV$I_COLOR_MAPPING = 0

get_figure_index = function() {
    INDEX_ENV$I_FIGURE
}

increase_figure_index = function() {
    INDEX_ENV$I_FIGURE = INDEX_ENV$I_FIGURE + 1
}

get_heatmap_index = function() {
	INDEX_ENV$I_HEATMAP
}

increase_heatmap_index = function() {
	INDEX_ENV$I_HEATMAP = INDEX_ENV$I_HEATMAP + 1
}

get_annotation_index = function() {
	INDEX_ENV$I_ANNOTATION
}

increase_annotation_index = function() {
	INDEX_ENV$I_ANNOTATION = INDEX_ENV$I_ANNOTATION + 1
}

get_row_annotation_index = function() {
	INDEX_ENV$I_ROW_ANNOTATION
}

increase_row_annotation_index = function() {
	INDEX_ENV$I_ROW_ANNOTATION = INDEX_ENV$I_ROW_ANNOTATION + 1
}

get_color_mapping_index = function() {
    INDEX_ENV$I_COLOR_MAPPING
}

increase_color_mapping_index = function() {
    INDEX_ENV$I_COLOR_MAPPING = INDEX_ENV$I_COLOR_MAPPING + 1
}

# default colors for matrix or annotations
# this function should be improved later
default_col = function(x, main_matrix = FALSE) {

    if(is.factor(x)) {
        x = as.vector(x)
    }

    if(length(unique(as.vector(x))) == 1) {
        x = as.character(x)
    }

    attributes(x) = NULL

    x = x[!is.na(x)]

    if(is.character(x)) {  # discrete
        levels = unique(x)
        #colors = hsv(runif(length(levels)), 1-runif(1)/2, 1-runif(1)/2)
        colors = rand_color(length(levels), luminosity = sample(c("bright", "light", "dark", "random"), 1))
        names(colors) = levels
        return(colors)
    } else if(is.numeric(x)) {
        if(main_matrix) {
            p = sum(x > 0)/sum(x != 0)
            if(p > 0.25 & p < 0.75) {
                if(ht_opt$verbose) {
                    cat("This matrix has both negative and positive values, use a color mapping symmetric to zero\n")
                }
                if(length(unique(x)) >= 100) {
                    q1 = quantile(abs(x), 0.99)
                    col_fun = colorRamp2(c(-q1, 0, q1), c("blue", "#EEEEEE", "red"))
                } else {
                    q1 = max(abs(x))
                    col_fun = colorRamp2(c(-q1, 0, q1), c("blue", "#EEEEEE", "red"))
                }
            } else {
                if(length(unique(x)) >= 100) {
                    q1 = quantile(x, 0.01)
                    q2 = quantile(x, 0.99)
                    if(length(unique(x[x > q1 & x < q2])) == 1) {
                         col_fun = colorRamp2(seq(min(x), max(x), length = 3), c("blue", "#EEEEEE", "red"))
                    } else {
                        col_fun = colorRamp2(seq(q1, q2, length = 3), c("blue", "#EEEEEE", "red"))
                    }
                } else {
                    col_fun = colorRamp2(seq(min(x), max(x), length = 3), c("blue", "#EEEEEE", "red"))
                }
            }
        } else {
            #col_fun = colorRamp2(range(min(x), max(x)), c("white", hsv(runif(1), 1, 1)))
            col_fun = colorRamp2(range(min(x), max(x)), c("white", rand_color(1, luminosity = sample(c("bright", "dark"), 1))))
        }
        return(col_fun)
    }
}

# == title
# Calculate Pairwise Distance from a Matrix
#
# == param
# -x A matrix or a list. If it is a matrix, the distance is calculated by rows.
# -pairwise_fun A function which calculates distance between two vectors.
# -... Pass to `stats::as.dist`.
#
# == detail
# You can construct any type of distance measurements by defining a pair-wise distance function.
# The function is implemented by two nested ``for`` loops, so the efficiency may not be so good.
#
# == value
# A `stats::dist` object.
#
# == author
# Zuguang Gu <z.gu@dkfz.de>
#
# == example
# lt = lapply(1:10, function(i) {
#     sample(letters, sample(6:10, 1))
# })
# dist2(lt, function(x, y) {
#     length(intersect(x, y))/length(union(x, y))
# })
dist2 = function(x, pairwise_fun = function(x, y) sqrt(sum((x - y)^2)), ...) {

    if(is.matrix(x)) {
        if(nrow(x) < 2) {
            stop_wrap("`x` should have at least two rows.")
        }

        nr = nrow(x)
        mat2 = matrix(NA, nrow = nr, ncol = nr)
        rownames(mat2) = colnames(mat2) = rownames(x)

        for(i in 2:nr) {
            for(j in 1:(nr-1)) {
                mat2[i, j] = pairwise_fun(x[i, ], x[j, ])
            }
        }

        as.dist(mat2, ...)
    } else if(is.list(x)) {
        if(length(x) < 2) {
            stop_wrap("`x` should have at least length of 2.")
        }

        nr = length(x)
        mat2 = matrix(NA, nrow = nr, ncol = nr)
        rownames(mat2) = colnames(mat2) = names(x)

        for(i in 2:nr) {
            for(j in 1:(nr-1)) {
                mat2[i, j] = pairwise_fun(x[[i]], x[[j]])
            }
        }
        as.dist(mat2, ...)
    } else {
        stop_wrap("`x` can be a matrix or a list.")
    }
}


get_dist = function(matrix, method) {
    if(is.function(method)) {
        nargs = length(as.list(args(method)))
        if(nargs == 2) { # a distance function
            dst = method(matrix)
        } else if(nargs == 3) {
            dst = dist2(matrix, method)
        } else {
            stop_wrap("Since your distance method is a function, it can only accept one or two arguments.")
        }
    } else if(method %in% c("euclidean", "maximum", "manhattan", "canberra", "binary", "minkowski")) {
        # if(any(is.na(matrix))) {
        #     dst = get_dist(matrix, function(x, y) {
        #         l = is.na(x) | is.na(y)
        #         x = x[!l]
        #         y = y[!l]
        #         as.vector(dist(rbind(x, y), method = method))
        #     })
        #     warning("NA exists in the matrix, calculating distance by removing NA values.")
        # } else {
            dst = dist(matrix, method = method)
        # }
    } else if(method %in% c("pearson", "spearman", "kendall")) {
        if(any(is.na(matrix))) {
            dst = get_dist(matrix, function(x, y) {
                    l = is.na(x) | is.na(y)
                    x = x[!l]
                    y = y[!l]
                    1 - cor(x, y, method = method)
                })
            warning_wrap("NA exists in the matrix, calculating distance by removing NA values.")
        } else {
            dst = switch(method,
                         pearson = as.dist(1 - cor(t(matrix), method = "pearson")),
                         spearman = as.dist(1 - cor(t(matrix), method = "spearman")),
                         kendall = as.dist(1 - cor(t(matrix), method = "kendall")))
        }
    }
    return(dst)
}

get_dend_order = function(x) {
    switch(class(x),
        hclust = x$order,
        dendrogram = order.dendrogram(x))
}

recycle_gp = function(gp, n = 1) {
    for(i in seq_along(gp)) {
        x = gp[[i]]
        gp[[i]] = c(rep(x, floor(n/length(x))), x[seq_len(n %% length(x))])
    }
    return(gp)
}

check_gp = function(gp) {
    if(!inherits(gp, "gpar")) {
        stop_wrap("Graphic parameters should be specified by `gpar()`.")
    }
    return(gp)
}


# == title
# Subset a gpar Object
#
# == param
# -gp A `gpar` object.
# -i A vector of indices.
#
# == value
# A `grid::gpar` object.
#
# == example
# gp = gpar(col = 1:10, fill = 1)
# subset_gp(gp, 1:5)
subset_gp = function(gp, i) {
    gp = lapply(gp, function(x) {
        if(length(x) == 1) x
        else x[i]
    })
    class(gp) = "gpar"
    return(gp)
}


get_text_just = function(rot, side) {
    rot = rot %% 360
    if(! rot %in% c(0, 90, 270)) {
        stop_wrap("Only support horizontal or vertical rotations for text.\n")
    }
    if(side == "left") {
        if(rot == 0) {
            return(c(1, 0.5))
        } else if(rot == 90) {
            return(c(0.5, 0))
        } else if(rot == 270) {
            return(c(0.5, 1))
        }
    } else if(side == "right") {
        if(rot == 0) {
            return(c(0, 0.5))
        } else if(rot == 90) {
            return(c(0.5, 1))
        } else if(rot == 270) {
            return(c(0.5, 0))
        }
    } else if(side == "top") {
        if(rot == 0) {
            return(c(0.5, 0))
        } else if(rot == 90) {
            return(c(0, 0.5))
        } else if(rot == 270) {
            return(c(1, 0.5))
        }
    } else if(side == "bottom") {
        if(rot == 0) {
            return(c(0.5, 1))
        } else if(rot == 90) {
            return(c(1, 0.5))
        } else if(rot == 270) {
            return(c(0, 0.5))
        }
    }
}

c.list = function(lt, ..., list = NULL) {
    if(length(lt) == 0) lt = list()

    if(is.null(list)) {
        lt_add = list(...)

        n = length(lt)
        for(i in seq_along(lt_add)) {
            lt[[n+i]] = lt_add[[i]]
        }
    } else {
        lt = c(lt, list)
    }
    return(lt)
}

rep.list = function(x, n) {
    lt = vector("list", n)
    for(i in seq_len(n)) {
        lt[i] = list(x)
    }
    return(lt)
}

# == title
# List All Heatmap Components
#
# == value
# A vector of viewport names.
#
list_components = function() {
    vp = grid.ls(viewports = TRUE, grobs = FALSE, flatten = FALSE, print = FALSE)
    vp = unlist(vp)
    attributes(vp) = NULL
    vp = vp[!grepl("^\\d+$", vp)]
    vp = vp[!grepl("GRID.VP", vp)]
    # unique(vp)
    vp
}

# == title
# Maximum Width of Text
#
# == param
# -text A vector of text.
# -gp Graphic parameters for text.
# -rot Rotation of the text, scalar.
#
# == details
# It simply calculates maximum width of a list of `grid::textGrob` objects.
#
# Note it ignores the text rotation.
#
# == value
# A `grid::unit` object which is in "mm".
#
# == author
# Zuguang Gu <z.gu@dkfz.de>
#
# == seealso
# `max_text_height` calculates the maximum height of a text vector.
#
# == example
# x = c("a", "bb", "ccc")
# max_text_width(x, gp = gpar(fontsize = 10))
#
max_text_width = function(text, gp = gpar(), rot = 0) {
    if(is.null(text)) {
        return(unit(0, "mm"))
    }
    n = length(text)
    gp = recycle_gp(gp, n)

    u = max(do.call("unit.c", lapply(seq_len(n), function(i) grobWidth(textGrob(text[i], gp = subset_gp(gp, i), rot = rot)))))
    convertWidth(u, "mm")
}

# == title
# Maximum Height of Text
#
# == param
# -text A vector of text.
# -gp Graphic parameters for text.
# -rot Rotation of the text, scalar.
#
# == details
# It simply calculates maximum height of a list of `grid::textGrob` objects.
#
# Note it ignores the text rotation.
#
# == value
# A `grid::unit` object.
#
# == author
# Zuguang Gu <z.gu@dkfz.de>
#
# == seealso
# `max_text_width` calculates the maximum width of a text vector.
#
# == example
# x = c("a", "b\nb", "c\nc\nc")
# max_text_height(x, gp = gpar(fontsize = 10))
#
max_text_height = function(text, gp = gpar(), rot = 0) {
    if(is.null(text)) {
        return(unit(0, "mm"))
    }
    n = length(text)
    gp = recycle_gp(gp, n)

    u = max(do.call("unit.c", lapply(seq_len(n), function(i) grobHeight(textGrob(text[i], gp = subset_gp(gp, i), rot = rot)))))
    convertHeight(u, "mm")
}

text_width = function(text, gp = gpar()) {
    if(is.null(text)) {
        return(unit(0, "mm"))
    }
    n = length(text)
    gp = recycle_gp(gp, n)

    u = do.call("unit.c", lapply(seq_len(n), function(i) grobWidth(textGrob(text[i], gp = subset_gp(gp, i)))))
    convertWidth(u, "mm")
}

text_height = function(text, gp = gpar()) {
    if(is.null(text)) {
        return(unit(0, "mm"))
    }
    n = length(text)
    gp = recycle_gp(gp, n)

    u = do.call("unit.c", lapply(seq_len(n), function(i) grobHeight(textGrob(text[i], gp = subset_gp(gp, i)))))
    convertHeight(u, "mm")
}

dev.null = function(...) {
    pdf(file = NULL, ...)
}

stop_wrap = function (...) {
    x = paste0(...)
    x = paste(strwrap(x), collapse = "\n")
    stop(x, call. = FALSE)
}

warning_wrap = function (...) {
    x = paste0(...)
    x = paste(strwrap(x), collapse = "\n")
    warning(x, call. = FALSE)
}

message_wrap = function (...) {
    x = paste0(...)
    x = paste(strwrap(x), collapse = "\n")
    message(x)
}

generate_param_list_fun = function(default) {
    if(!is.list(default)) {
        stop_wrap("`default` needs to be a list.")
    }
    lt = default
    function(..., list = NULL) {
        if(missing(list)) {
            lt2 = list(...)
        } else {
            lt2 = list
        }
        for(nm in intersect(names(lt), names(lt2))) {
            lt[[nm]] = lt2[[nm]]
        }
        return(lt)
    }
}

add_vp_name = function(vpname) {
    grid.text(vpname, 0, 1, just = c("left", "top"), gp = gpar(fontsize = 6, col = "red"))
}

upViewport = function(...) {
    if(ht_global_opt$show_vp) {
        grid.rect(gp = gpar(fill = "transparent", col = "black", lty = 3))
        vpname = current.viewport()$name
        if(!grepl("^GRID.VP", vpname)) {
            add_vp_name(vpname)
        }
    }
    grid::upViewport(...)
}

popViewport = function(...) {
    if(ht_global_opt$show_vp) {
        grid.rect(gp = gpar(fill = "transparent", col = "black", lty = 3))
        vpname = current.viewport()$name
        if(!grepl("^GRID.VP", vpname)) {
            add_vp_name(vpname)
        }
    }
    grid::popViewport(...)
}


dev.off2 = function () {
    i1 = dev.prev()
    i2 = dev.cur()

    if (i1 == 2) {
        dev.set(i1)
    } else if(i1 > 2) {
        i11 = dev.prev(i1)
        if(names(i11) == "RStudioGD") {
            dev.set(i11)
        } else {
            dev.set(i1)
        }
    }
    dev.off(i2)
}

unit.c = function(...) {
    lt = list(...)
    lt = lt[!sapply(lt, is.null)]
    do.call(grid::unit.c, lt)
}

">.unit" = function(x, y) {
    if(!unit_in_mm(x)) {
        stop_wrap("x should be in mm unit")
    }
    if(!unit_in_mm(y)) {
        stop_wrap("y should be in mm unit")
    }
    as.numeric(x) > as.numeric(y)
}

"<.unit" = function(x, y) {
    if(!unit_in_mm(x)) {
        stop_wrap("x should be in mm unit")
    }
    if(!unit_in_mm(y)) {
        stop_wrap("y should be in mm unit")
    }
    as.numeric(x) < as.numeric(y)
}

unit_in_mm = function(x) {
    identical(unitType(x), "mm")
}

unit_to_numeric = function(x) {
    as.numeric(x)
}

normalize_graphic_param_to_mat = function(x, nc, nr, name) {
    if(is.matrix(x)) {
        if(nrow(x) == nr && ncol(x) == nc) {
            return(x)
        } else {
            stop_wrap(paste0(name, "needs to be a matrix with ", nc, " columns and ", nr, " rows."))
        }
    } else {
        if(length(x) == nc) {
            return(matrix(rep(x, each = nr), ncol = nc))
        } else if(length(x) == nr) {
            return(matrix(rep(x, times = nc), ncol = nc))
        } else if(length(x) == 1) {
            return(matrix(x, ncol = nc, nrow = nr))
        } else {
            stop_wrap(paste0("Since ", name, " is a vector, it should have length of ", nc, " or ", nr, "."))
        }
    }
}

recycle_param = function(x, all_names, default, as.list = FALSE) {
    n = length(all_names)
    if(length(x) == 0) {
        if(as.list) {
            rep(list(default), n)
        } else {
            rep(default, n)
        }
    } else if(length(x) == n) {
        if(as.list) {
            x = lapply(1:n, function(i) x[i])
        }
        return(x)
    } else {
        nm = names(x)
        if(length(intersect(nm, all_names)) == 0) {
            nm = NULL
        }
        if(is.null(nm)) {
            if(length(x) == 1) {
                if(as.list) {
                    x = rep(list(x), n)
                } else {
                    x = rep(x, n)
                }
            } else {
                if(length(x) > n) {
                    x = x[1:n]
                    if(as.list) {
                        x = lapply(1:n, function(i) x[i])
                    }
                } else {
                    if(as.list) {
                        x = c(lapply(seq_along(x), function(i) x[i], 
                              rep(list(default), n - length(x))))
                    } else {
                        x = c(x, rep(default, n - length(x)))
                    }
                }
            }
        } else {
            if(as.list) {
                x2 = rep(list(default), n)
                names(x2) = all_names
                for(cn in intersect(nm, all_names)) {
                    x2[[cn]] = x[cn]
                }
                x = x2
            } else {
                x2 = structure(rep(default, n), names = all_names)
                x2[intersect(nm, all_names)] = x[intersect(nm, all_names)]
                x = x2
            }
        }
        return(x)
    }
}

# == title
# Convert XY in a Parent Viewport
#
# == param
# -u A list of two units which correspond to x and y.
# -vp_name The name of the parent viewport.
#
# == details
# It converts a coordinate measured in current viewport to the coordinate in a parent viewport.
#
# In the conversion, all units are recalculated as absolute units, so if you change the size
# of the interactive graphic window, you need to rerun the function.
#
# == value
# A list of two units.
# 
# == example
# grid.newpage()
# pushViewport(viewport(x = 0.5, y = 0.5, width = 0.5, height = 0.5, just = c("left", "bottom")))
# grid.rect()
# grid.points(x = unit(2, "cm"), y = unit(2, "cm"), pch = 1)
# u = list(x = unit(2, "cm"), y = unit(2, "cm"))
# u2 = getXY_in_parent_vp(u)
# popViewport()
# grid.rect(gp = gpar(col = "red"))
# grid.points(x = u2$x, u2$y, pch = 2)
getXY_in_parent_vp = function(u, vp_name = "ROOT") {
    if(inherits(u, "unit")) {
        if(length(u) == 2) {
            u = list(x = u[1], y = u[2])
        } else {
            stop_wrap("If `u` is a unit vector, it must have length of 2.")
        }
    }
    if(length(u) != 2) {
        stop_wrap("`u` should be a list of length of 2 (two elements: `x` and `y`).")
    }
    if(is.null(names(u))) {
        names(u) = c("x", "y")
    }

    vp = current.viewport()
    current_vp_name = vp$name
    original_vp_name = current_vp_name
    on.exit(seekViewport(original_vp_name))

    if(current_vp_name == "ROOT") {
        return(u)
    }
    while(current_vp_name != vp_name) {

        if(current_vp_name == "ROOT") {
            stop_wrap(qq("Cannot find a parent viewport with name \"@{vp_name}\"."))
        }

        u$x = convertX(u$x, "mm")
        u$y = convertX(u$y, "mm")
        # vp is measured in parent vp
        current_vp_x = vp$x - vp$width*vp$valid.just[1]
        current_vp_y = vp$y - vp$height*vp$valid.just[2]

        upViewport(1)
        offset_x = convertX(current_vp_x, "mm")
        offset_y = convertY(current_vp_y, "mm")
        u$x = u$x + offset_x
        u$y = u$y + offset_y

        vp = current.viewport()
        current_vp_name = vp$name
    }

    return(u)
}

# == title
# Get Values in a Matrix by Pair-wise Indices
#
# == param
# -m A matrix or a 3-dimension array.
# -i Row indices or the indices in the first dimension.
# -j Column indicies or the indices in the second dimension.
#
# == value
# If ``m`` is a matrix, the value returned is a vector ``c(m[i1, j1], m[i2, j2], ...)```. 
#
# If ``m`` is an array, the value returned is a matrix ``rbind(m[i1, j1, ], m[i2, j2, ], ...)```.
#
# == example
# m = matrix(rnorm(100), 10)
# m2 = m[m > 0]
# ind = do.call("rbind", lapply(1:10, function(ci) {
#     i = which(m[, ci] > 0)
#     cbind(i = i, j = rep(ci, length(i)))
# }))
# pindex(m, ind[, 1], ind[, 2])
# identical(pindex(m, ind[, 1], ind[, 2]), m[m > 0])
#
# # 3d array
# arr = array(1:27, dim = c(3, 3, 3))
# pindex(arr, 1:2, 2:3)
# identical(pindex(arr, 1:2, 2:3),
#    rbind(arr[1, 2, ], arr[2, 3, ]))
pindex = function(m, i, j) {

    if(length(i) == 1) i = rep(i, length(j))
    if(length(j) == 1) j = rep(j, length(i))
    if(length(i) != length(j)) {
        stop_wrap("Length of index i and j should be the same.")
    }

    nr = nrow(m)
    nc = ncol(m)
    ind = (j-1)*nr + i
    dm = dim(m)
    if(length(dm) == 2) {
        v = as.vector(m)
        v[ind]
    } else if(length(dm) == 3) {
        v = m
        dim(v) = c(dm[1]*dm[2], dm[3])
        v[ind, , drop = FALSE]
    } else {
        stop_wrap("dimension of `m` can only be 2 and 3.")
    }
}

# == title
# Restore the index vector to index matrix in layer_fun
#
# == param
# -j Column indices directly from ``layer_fun``.
# -i Row indices directly from ``layer_fun``.
# -x Position on x-direction directly from ``layer_fun``.
# -y Position on y-direction directly from ``layer_fun``.
#
# == details
# The values that are sent to ``layer_fun`` are all vectors (for the vectorization
# of the grid graphic functions), however, the heatmap slice where
# ``layer_fun`` is applied to, is still represented by a matrix, thus, it would be
# very convinient if all the arguments in ``layer_fun`` can be converted to the
# sub-matrix for the current slice. Here, as shown in above example,
# `restore_matrix` does the job. `restore_matrix` directly accepts the first
# four argument in ``layer_fun`` and returns an index matrix, where rows and
# columns correspond to the rows and columns in the current slice, from top to
# bottom and from left to right. The values in the matrix are the natural order
# of e.g. vector ``j`` in current slice.
#
# For following code:
#
#     Heatmap(small_mat, name = "mat", col = col_fun,
#         row_km = 2, column_km = 2,
#         layer_fun = function(j, i, x, y, w, h, fill) {
#             ind_mat = restore_matrix(j, i, x, y)
#             print(ind_mat)
#         }
#     )
#
# The first output which is for the top-left slice:
# 
#          [,1] [,2] [,3] [,4] [,5]
#     [1,]    1    4    7   10   13
#     [2,]    2    5    8   11   14
#     [3,]    3    6    9   12   15
#
# As you see, this is a three-row and five-column index matrix where the first
# row corresponds to the top row in the slice. The values in the matrix
# correspond to the natural index (i.e. 1, 2, ...) in ``j``, ``i``, ``x``, ``y``,
# ... in ``layer_fun``. Now, if we want to add values on the second column in the
# top-left slice, the code which is put inside ``layer_fun`` would look like:
#
#     for(ind in ind_mat[, 2]) {
#         grid.text(small_mat[i[ind], j[ind]], x[ind], y[ind], ...)
#     }
#
# == example
# set.seed(123)
# mat = matrix(rnorm(81), nr = 9)
# Heatmap(mat, row_km = 2, column_km = 2,
#     layer_fun = function(j, i, x, y, width, height, fill) {
#        ind_mat = restore_matrix(j, i, x, y)
#        print(ind_mat)
# })
#
# set.seed(123)
# mat = matrix(round(rnorm(81), 2), nr = 9)
# Heatmap(mat, row_km = 2, column_km = 2,
#     layer_fun = function(j, i, x, y, width, height, fill) {
#        ind_mat = restore_matrix(j, i, x, y)
#        ind = unique(c(ind_mat[2, ], ind_mat[, 3]))
#        grid.text(pindex(mat, i[ind], j[ind]), x[ind], y[ind])
# })
restore_matrix = function(j, i, x, y) {
    x = as.numeric(x)
    y = as.numeric(y)
    od = order(x, rev(y))
    ind = seq_along(i)
    j = j[od]
    i = i[od]
    x = x[od]
    y = y[od]
    ind = ind[od]
    
    nr = length(unique(i))
    nc = length(unique(j))
    # I = matrix(i, nrow = nr, ncol = nc)
    # J = matrix(j, nrow = nr, ncol = nc)
    IND = matrix(ind, nrow = nr, ncol = nc)
    return(IND)
}


unit_with_vp = function(..., vp = current.viewport()$name) {
    u = unit(...)
    attr(u, "viewport") = vp
    return(u)
}


# == title
# Draw a Single Boxplot
#
# == param
# -value A vector of numeric values.
# -pos Position of the boxplot.
# -outline Whether draw outlines?
# -box_width width of the box.
# -pch Point type.
# -size Point size.
# -gp Graphic parameters.
# -direction Whether the box is vertical or horizontal.
#
# == details
# All the values are measured with ``native`` coordinate.
#
# == example
# lt = list(rnorm(100), rnorm(100))
# grid.newpage()
# pushViewport(viewport(xscale = c(0.5, 2.5), yscale = range(lt)))
# grid.boxplot(lt[[1]], pos = 1, gp = gpar(fill = "red"))
# grid.boxplot(lt[[2]], pos = 2, gp = gpar(fill = "green"))
# popViewport()
grid.boxplot = function(value, pos, outline = TRUE, box_width = 0.6,
    pch = 1, size = unit(2, "mm"), gp = gpar(fill = "#CCCCCC"), 
    direction = c("vertical", "horizontal")) {

    direction = match.arg(direction)[1]
    boxplot_stats = boxplot(value, plot = FALSE)$stats

    if(direction == "vertical") {
        grid.rect(x = pos, y = boxplot_stats[2, 1], 
            height = boxplot_stats[4, 1] - boxplot_stats[2, 1], width = 1*box_width, just = "bottom", 
            default.units = "native", gp = gp)
        
        grid.segments(pos - 0.5*box_width, boxplot_stats[5, 1],
                      pos + 0.5*box_width, boxplot_stats[5, 1], 
                      default.units = "native", gp = gp)
        grid.segments(pos, boxplot_stats[5, 1],
                      pos, boxplot_stats[4, 1], 
                      default.units = "native", gp = gp)
        grid.segments(pos, boxplot_stats[1, 1],
                      pos, boxplot_stats[2, 1], 
                      default.units = "native", gp = gp)
        grid.segments(pos - 0.5*box_width, boxplot_stats[1, 1],
                      pos + 0.5*box_width, boxplot_stats[1, 1], 
                      default.units = "native", gp = gp)
        grid.segments(pos - 0.5*box_width, boxplot_stats[3, 1],
                      pos + 0.5*box_width, boxplot_stats[3, 1], 
                      default.units = "native", gp = gp)
        if(outline) {   
            l1 = value > boxplot_stats[5, 1]
            if(sum(l1)) grid.points(x = rep(pos, sum(l1)), y = value[l1], 
                default.units = "native", gp = gp, pch = pch, size = size)
            l2 = value < boxplot_stats[1, 1]
            if(sum(l2)) grid.points(x = rep(pos, sum(l2)), y = value[l2], 
                default.units = "native", gp = gp, pch = pch, size = size) 
        }
    } else {
        grid.rect(y = pos, x = boxplot_stats[2, 1], 
            width = boxplot_stats[4, 1] - boxplot_stats[2, 1], height = 1*box_width, just = "left", 
            default.units = "native", gp = gp)
        
        grid.segments(boxplot_stats[5, 1], pos - 0.5*box_width,
                      boxplot_stats[5, 1], pos + 0.5*box_width,
                      default.units = "native", gp = gp)
        grid.segments(boxplot_stats[5, 1], pos,
                      boxplot_stats[4, 1], pos,
                      default.units = "native", gp = gp)
        grid.segments(boxplot_stats[1, 1], pos,
                      boxplot_stats[2, 1], pos,
                      default.units = "native", gp = gp)
        grid.segments(boxplot_stats[1, 1], pos - 0.5*box_width,
                      boxplot_stats[1, 1], pos + 0.5*box_width,
                      default.units = "native", gp = gp)
        grid.segments(boxplot_stats[3, 1], pos - 0.5*box_width,
                      boxplot_stats[3, 1], pos + 0.5*box_width,
                      default.units = "native", gp = gp)
        if(outline) {   
            l1 = value > boxplot_stats[5, 1]
            if(sum(l1)) grid.points(y = rep(pos, sum(l1)), x = value[l1], 
                default.units = "native", gp = gp, pch = pch, size = size)
            l2 = value < boxplot_stats[1, 1]
            if(sum(l2)) grid.points(y = rep(pos, sum(l2)), x = value[l2], 
                default.units = "native", gp = gp, pch = pch, size = size) 
        }
    }
}

random_str = function(k = 1, len = 10) {
    sapply(seq_len(k), function(i) paste(sample(c(letters, LETTERS, 0:9), len), collapse = ""))
}



to_unit_str = function(unit) {
    as.character(unit)
}

to_unit = function(str) {
    d = gsub("[^\\d]+$", "", str, perl = TRUE)
    u = gsub("[\\d.]", "", str, perl = TRUE)
    unit(as.numeric(d), u)
}


resize_matrix = function(mat, nr, nc) {
    w_ratio = nc/ncol(mat)
    h_ratio = nr/nrow(mat)
    mat[ ceiling(1:nr / h_ratio), ceiling(1:nc / w_ratio), drop = FALSE]
}


# == title
# Adjust positions of rectanglar shapes
#
# == param
# -start position which corresponds to the start (bottom or left) of the rectangle-shapes.
# -end position which corresponds to the end (top or right) of the rectanglar shapes.
# -range data ranges (the minimal and maximal values)
# -range_fixed Whether the range is fixed for ``range`` when adjust the positions?
#
# == details
# This is an improved version of the `circlize::smartAlign`.
#
# It adjusts the positions of the rectangular shapes to make them do not overlap
#
# == example
# require(circlize)
# make_plot = function(pos1, pos2, range) {
#     oxpd = par("xpd")
#     par(xpd = NA)
#     plot(NULL, xlim = c(0, 4), ylim = range, ann = FALSE)
#     col = rand_color(nrow(pos1), transparency = 0.5)
#     rect(0.5, pos1[, 1], 1.5, pos1[, 2], col = col)
#     rect(2.5, pos2[, 1], 3.5, pos2[, 2], col = col)
#     segments(1.5, rowMeans(pos1), 2.5, rowMeans(pos2))
#     par(xpd = oxpd)
# }
#
# range = c(0, 10)
# pos1 = rbind(c(1, 2), c(5, 7))
# make_plot(pos1, smartAlign2(pos1, range = range), range)
#
# range = c(0, 10)
# pos1 = rbind(c(-0.5, 2), c(5, 7))
# make_plot(pos1, smartAlign2(pos1, range = range), range)
#
# pos1 = rbind(c(-1, 2), c(3, 4), c(5, 6), c(7, 11))
# pos1 = pos1 + runif(length(pos1), max = 0.3, min = -0.3)
# omfrow = par("mfrow")
# par(mfrow = c(3, 3))
# for(i in 1:9) {
#     ind = sample(4, 4)
#     make_plot(pos1[ind, ], smartAlign2(pos1[ind, ], range = range), range)
# }
# par(mfrow = omfrow)
#
# pos1 = rbind(c(3, 6), c(4, 7))
# make_plot(pos1, smartAlign2(pos1, range = range), range)
#
# pos1 = rbind(c(1, 8), c(3, 10))
# make_plot(pos1, smartAlign2(pos1, range = range), range)
# make_plot(pos1, smartAlign2(pos1, range = range, range_fixed = FALSE), range)
#
smartAlign2 = function(start, end, range, range_fixed = TRUE) {

    if(missing(end)) {
        x1 = start[, 1]
        x2 = start[, 2]
    } else {
        x1 = start
        x2 = end
    }

    if(missing(range)) {
        range = range(c(x1, x2))
    }

    od = order(x1)
    rk = rank(x1, ties.method = "random")
    x1 = x1[od]
    x2 = x2[od]
    h = x2 - x1

    ncluster.before = -1
    ncluster = length(x1)
    i_try = 0
    while(ncluster.before != ncluster) {
        ncluster.before = ncluster
        cluster = rep(0, length(x1))
        i_cluster = 1
        cluster[1] = i_cluster
        for(i in seq_along(x1)[-1]) {
            # overlap with previous one
            if(x1[i] <= x2[i-1]) {  # this means x1 should be sorted increasingly
                cluster[i] = i_cluster
            } else {
                i_cluster = i_cluster + 1
                cluster[i] = i_cluster
            }
        }
        ncluster = length(unique(cluster))
        
        if(ncluster.before == ncluster && i_try > 0) break

        if(i_try > 100) break
        
        # tile intervals in each cluster and re-assign x1 and x2
        new_x1 = numeric(length(x1))
        new_x2 = numeric(length(x2))
        for(i_cluster in unique(cluster)) {
            index = which(cluster == i_cluster)
            total_len = sum(x2[index] - x1[index])  # sum of the height in the cluster
            mid = (min(x1[index]) + max(x2[index]))/2
            if(total_len > range[2] - range[1]) {
                # tp = seq(range[1], range[2], length = length(index) + 1)
                if(range_fixed) {
                    tp = cumsum(c(0, h[index]/sum(h[index])))*(range[2] - range[1]) + range[1]
                } else {
                    tp = c(0, cumsum(h[index])) + mid - sum(h[index])/2
                }
            } else if(mid - total_len/2 < range[1]) { # if it exceed the bottom
                # tp = seq(range[1], range[1] + total_len, length = length(index) + 1)
                tp = c(0, cumsum(h[index])) + range[1]
            } else if(mid + total_len/2 > range[2]) {
                # tp = seq(range[2] - total_len, range[2], length = length(index) + 1)
                tp = range[2] - rev(c(0, cumsum(h[index])))
            } else {
                # tp = seq(mid - total_len/2, mid + total_len/2, length = length(index)+1)
                tp = c(0, cumsum(h[index])) + mid - sum(h[index])/2
            }
            new_x1[index] = tp[-length(tp)]
            new_x2[index] = tp[-1]
        }
        mid = (new_x1 + new_x2)/2
        h = (x2 - x1)
        
        x1 = mid - h/2
        x2 = mid + h/2

        i_try = i_try + 1
    }
    
    df = data.frame(start = x1, end = x2)
    df[rk, , drop = FALSE]
}

color_overlap = function (r0, g0, b0, r, g, b, alpha = 1) {
    l_na_1 = is.na(r0) | is.na(g0) | is.na(b0)
    l_na_2 = is.na(r) | is.na(g) | is.na(b)
    r = ifelse(l_na_1 & l_na_2, 1, ifelse(l_na_1, r * alpha,
        ifelse(l_na_2, r0, r * alpha + r0 * (1 - alpha))))
    g = ifelse(l_na_1 & l_na_2, 1, ifelse(l_na_1, g * alpha,
        ifelse(l_na_2, g0, g * alpha + g0 * (1 - alpha))))
    b = ifelse(l_na_1 & l_na_2, 1, ifelse(l_na_1, b * alpha,
        ifelse(l_na_2, b0, b * alpha + b0 * (1 - alpha))))
    return(list(r = r, g = g, b = b))
}

colorRamp2_biv = function(f1, f2, transparency = 0.5) {
    f1 = f1
    f2 = f2
    if(length(transparency) == 1) transparency = rep(transparency, 2)
    f = function(x1, x2) {
        if(missing(x2)) {
            if(ncol(x1) == 2) {
                x2 = x1[, 2]
                x1 = x1[, 1]
            } else {
                stop_wrap("If only one variable is specified, it should be a matrix/data frame with two columns.")
            }
        }
        col1 = col2rgb(f1(x1), alpha = TRUE)/255
        col2 = col2rgb(f2(x2), alpha = TRUE)/255

        if(length(transparency)) {
            col1[4, ] = 1 - transparency[1]
            col2[4, ] = 1 - transparency[2]
        }

        col1 = col1[1:3, , drop = FALSE] * rep(col1[4, ], each = 3)
        lt = color_overlap(col1[1, ], col1[2, ], col1[3, ],
            col2[1, ], col2[2, ], col2[3, ], alpha = col2[4, ])
        rgb(lt[[1]], lt[[2]], lt[[3]])
    }
}

