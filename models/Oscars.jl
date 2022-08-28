module Oscars

using Stipple
using StippleUI
using StipplePlotly
using PlotlyBase
using SQLite
using DataFrames
using MultivariateStats, CSV
import Colors
import ColorSchemes

db_multi = DataFrame()
db_multi[!,"System name"] = ["White Matter", "Telencephalon", "Diencephalon", "Mesencephalon","Metencephalon",
                          "Mylencephalon", "Spinal Cord", "Olfactory Epithelium",  "Hypothalamus",
                         "E. coli", "P. aeruginosa", "S. enterica", "V. cholerae", "Zebrafish Embryo",
                        "D. melongaster", "C. elegans",  "P. mammillata", "Cancer organoid", 
                        "Sphere packing", "1:1:4 ellipsoids", "1:4:4: ellipsoids", "1:2:3: ellipsoids", 
                        "Polydisperse packing", "Glassy material",  "Diffusion limited aggregation",
                        "Star positions", "Poisson-Voronoi"]
db_multi[!,"Number of points"] = vcat(ones(9),5*ones(4),10,14,ones(3),5*ones(5),3,5,1,5)
db_multi[!,"Number of cells per point (approx)"] = vcat(5_000,20_000,35_000,12_500,90_000,7_500,150_000,25_000,7_500,14_000,18_000*ones(4),20_000,43_500,3_200,2_100,10_000*ones(6),4096,110_000,10_000)

#TODO fix zebrafish region numbering
db_multi[!,"Search word"] = ["zebrafish_region_2","zebrafish_region_3", "zebrafish_region_4","zebrafish_region_5","zebrafish_region_6",
                        "zebrafish_region_7","zebrafish_region_8", "zebrafish_region_9","zebrafish_region_10",
                        "ecoli", "pseudomonas", "salmonella", "vibrio",  "zebrafish_embryo",
                        "fly_embryo","worm",  "ascidian", "Guo_organoid", 
                         "PackedSpheres", "PackedEllipses", "PackedMandM", "PackedIreg", "PolySpheres", 
                         "Glassy",  "DLA", "HYGStarDatabase", "PV/PV"]

d_mat = CSV.read(joinpath("data", "total_distance_compute.txt"), DataFrame)


const color_vec = vcat("#A6CEE2","#2179B4","#B4D88B","#36A047","#F6999A","#E21F26","#FDBF6F","#F57F20","#CAB3D6",
                    repeat(["#EC523F"],5),repeat(["#40A44A"],5),repeat(["#B276B2"],5),repeat(["#AB8E30"],5),repeat(["#4275B5"],10),
                    repeat(["#F47A51"],14),"#FFDE17", "#FDBF6D", "#2279B5", repeat(["#E12028","#37A048","#F57F20","#2279B5","#952768"],5),
                    repeat(["#942768"],5),repeat(["#E12028"],3),"#8E9738",repeat(["#8E9838"],5))

const color_dict = Dict("White Matter"=>"#A6CEE2",
                  "Telencephalon"=>"#2179B4",
                  "Diencephalon"=>"#B4D88B",
                  "Mesencephalon"=>"#36A047",
                  "Metencephalon"=>"#F6999A",
                  "Mylencephalon"=>"#E21F26",
                  "Spinal Cord"=>"#FDBF6F",
                  "Olfactory Epithelium"=>"#F57F20",
                  "Hypothalamus"=>"#CAB3D6",
                  "E. coli"=>"#EC523F", 
                  "P. aeruginosa"=>"#40A44A", 
                  "S. enterica"=>"#B276B2", 
                  "V. cholerae"=>"#AB8E30", 
                  "Zebrafish Embryo"=>"#4275B5",
                  "D. melongaster"=>"#F47A51", 
                  "C. elegans"=>"#FFDE17",  
                  "P. mammillata"=>"#FDBF6D", 
                  "Cancer organoid"=>"#2279B5", 
                  "Sphere packing"=>"#2179B4",
                  "1:1:4 ellipsoids"=>"#E21F26",
                  "1:4:4: ellipsoids"=>"#36A047",
                  "1:2:3: ellipsoids"=>"#F57F20",
                  "Polydisperse packing"=>"#942768", 
                  "Glassy material"=>"#E12028",  
                  "Diffusion limited aggregation"=>"#8E9838",
                  "Star positions"=>"#8E9738", 
                  "Poisson-Voronoi"=>"#942768")

symbol_dict = Dict("White Matter"=>"diamond",
                  "Telencephalon"=>"diamond",
                  "Diencephalon"=>"diamond",
                  "Mesencephalon"=>"diamond",
                  "Metencephalon"=>"diamond",
                  "Mylencephalon"=>"diamond",
                  "Spinal Cord"=>"diamond",
                  "Olfactory Epithelium"=>"diamond",
                  "Hypothalamus"=>"diamond",
                  "E. coli"=>"square", 
                  "P. aeruginosa"=>"square", 
                  "S. enterica"=>"square", 
                  "V. cholerae"=>"square", 
                  "Zebrafish Embryo"=>"circle",
                  "D. melongaster"=>"hexagon", 
                  "C. elegans"=>"triangle-down",  
                  "P. mammillata"=>"triangle-down", 
                  "Cancer organoid"=>"triangle-down", 
                  "Sphere packing"=>"triangle-up-open",
                  "1:1:4 ellipsoids"=>"triangle-up-open",
                  "1:4:4: ellipsoids"=>"triangle-up-open",
                  "1:2:3: ellipsoids"=>"triangle-up-open",
                  "Polydisperse packing"=>"triangle-up-open", 
                  "Glassy material"=>"square-open",  
                  "Diffusion limited aggregation"=>"circle-open",
                  "Star positions"=>"star-open", 
                  "Poisson-Voronoi"=>"square-open")                  

register_mixin(@__MODULE__)


const multi_table_options = DataTableOptions(columns = Column(["System name", "Number of points"]))

function replace_names(text_name)
  idx = findfirst(occursin.(db_multi[:,"Search word"],text_name))
  return db_multi[idx,"System name"]
end
function restricted_distance_matrix(ii)
  key_words  = db_multi[ii,"Search word"]
  idx_keep = [any(occursin.(key_words, n)) for n in names(d_mat)]
  text_names = names(d_mat)[idx_keep]
  return d_mat[idx_keep,idx_keep], replace_names.(text_names), color_vec[idx_keep]
end

function filtered_systems()
  ## will eventually return a filtered version of db_multi
  return db_multi
end

# processes the plot's data based on filters
function plot_data()
  PlotData( x = (1:10),
            y = (1:10),
            plot = StipplePlotly.Charts.PLOT_TYPE_SCATTER
          )
end

function plot_data_MDS(mds_coord,text_names,cvec)
  PlotData(
      x = mds_coord[:,1],
      y = mds_coord[:,2],
      name = "number of casts",
      mode = "markers",
      text = text_names,
      #marker = Dict(:color => "#035555",:symbol=>"square"),
      marker = Dict(:color => [color_dict[t] for t in text_names],
            :symbol=>[symbol_dict[t] for t in text_names]),
      plot = StipplePlotly.Charts.PLOT_TYPE_SCATTER
    )
end

function plot_layout(xtitle, ytitle)
  PlotLayout(
    xaxis = [PlotLayoutAxis(xy = "x",title = xtitle)],
    yaxis = [PlotLayoutAxis(xy = "y", title = ytitle, anchor="x",scaleratio=1)]#,
    #scaleanchor = "x"scaleanchor="x", scaleratio=1
  )
end

#=
function plot_annotate(xtitle, ytitle)
  PlotAnnotation(
    xaxis = [PlotLayoutAxis(title = xtitle)],
    yaxis = [PlotLayoutAxis(xy = "y", title = ytitle,anchor="x",scaleratio=1)]#,
    #scaleanchor = "x"scaleanchor="x", scaleratio=1
  )
end
=#

export Oscar

@reactive mutable struct Oscar <: ReactiveModel
  
  movies::R{DataTable} = DataTable(DataFrame())

  multi_systems::R{DataTable} = DataTable(filtered_systems(),multi_table_options)
  multi_systems_pagination::DataTablePagination = DataTablePagination(rows_per_page=50)
  multi_systems_selection::R{DataTableSelection} = DataTableSelection()

  selected_mvie::R{Dict} = Dict{String,Any}()
  data::R{Vector{PlotData}} = [plot_data()]
  layout::R{PlotLayout} = PlotLayout(plot_bgcolor = "#fff")
  
  
  one_way_traces::R{Vector{PlotData}} = [plot_data()]
  one_way_layout::R{PlotLayout} = PlotLayout(plot_bgcolor = "#fff")

  
  @mixin data::PlotlyEvents

  @mixin one_way_traces::PlotlyEvents
end

Stipple.js_mounted(::Oscar) = watchplots()

function handlers(model::Oscar)
  
  onany(model.multi_systems_selection, model.isready) do msel, i
    model.isprocessing[] = true

    ii = union(getindex.(msel, "__id"))
    if length(ii) == 0
      ii = 1:size(db_multi)[1]
    end
    d_mat_r, text_names, cvec = restricted_distance_matrix(ii)
    MDS_coords = permutedims(MultivariateStats.transform(MultivariateStats.fit(MDS,
        Matrix(d_mat_r), maxoutdim=3, distances=true)))
    
    model.data[] = [plot_data_MDS(MDS_coords[:,1:2],text_names,cvec)]
    model.one_way_traces[] = [plot_data_MDS(MDS_coords[:,2:3],text_names,cvec)]
    
    model.layout[] = plot_layout("MDS PC1", "MDS PC2")
    model.one_way_layout[] = plot_layout("MDS PC2", "MDS PC3")
    model.isprocessing[] = false
  end

  model
end

end