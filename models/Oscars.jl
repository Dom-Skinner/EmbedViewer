module Oscars

using Stipple
using StippleUI
using StipplePlotly
using PlotlyBase
using SQLite
using DataFrames
using MultivariateStats, CSV

const ALL = "All"
const db = SQLite.DB(joinpath("data", "oscars.db"))

db_multi = DataFrame()
db_multi[!,"System name"] = ["Hypothalamus","White Matter", "Telencephalon","Diencephalon","Mesencephalon",
                        "Olfactory Epithelium","Metencephalon", "Mylencephalon","Spinal Cord", 
                        "Zebrafish Embryo", "E. coli", "P. aeruginosa", "S. enterica", "V. cholerae", 
                        "D. melongaster", "P. mammillata", "Cancer organoid", "C. elegans", 
                        "Diffusion limited aggregation", "Sphere packing", "1:1:4 ellipsoids", 
                        "1:4:4: ellipsoids", "1:2:3: ellipsoids", "Polydisperse packing", "Glassy material", 
                        "Star positions", "Poisson-Voronoi"]
db_multi[!,"Number of points"] = vcat(ones(9),6,5,5,5,5,14,1,1,1,5*ones(6),3,1,5)
db_multi[!,"Number of cells per point (approx)"] = vcat(5_000,20_000,35_000,12_500,90_000,7_500,150_000,25_000,7_500,14_000,18_000*ones(4),20_000,43_500,3_200,2_100,10_000*ones(6),4096,110_000,10_000)

#TODO fix zebrafish region numbering
db_multi[!,"Search word"] = ["zebrafish_region_1","zebrafish_region_1", "zebrafish_region_1","zebrafish_region_1","zebrafish_region_1",
                        "zebrafish_region_1","zebrafish_region_8", "zebrafish_region_9","Spinal Cord", 
                        "zebrafish_embryo", "ecoli", "pseudomonas", "salmonella", "vibrio", 
                        "fly_embryo", "ascidian", "Guo_organoid", "worm", 
                        "DLA", "PackedSpheres", "PackedEllipses", 
                        "PackedMandM", "PackedIreg", "PolySpheres", "Glassy", 
                        "HYGStarDatabase", "PV/PV"]

d_mat = CSV.read(joinpath("data", "total_distance_compute.txt"), DataFrame)

register_mixin(@__MODULE__)

# construct a range between the minimum and maximum number of oscars
const oscars_range = begin
  result = DBInterface.execute(db, "select min(Oscars) as min_oscars, max(Oscars) as max_oscars from movies") |> DataFrame
  UnitRange(result[!,:min_oscars][1], result[!,:max_oscars][1])
end

# construct a range between the minimum and maximim years of the movies
const years_range = begin
  result = DBInterface.execute(db, "select min(Year) as min_year, max(Year) as max_year from movies") |> DataFrame
  UnitRange(result[!,:min_year][1], result[!,:max_year][1])
end

#const table_options = DataTableOptions(columns = Column(["Title", "Year", "Oscars", "Country", "Genre", "Director", "Cast"]))
const table_options = DataTableOptions(columns = Column(["Title", "Year", "Oscars", "Country", "Cast"]))
const multi_table_options = DataTableOptions(columns = Column(["System name", "Number of points"]))

function replace_names(text_name)
  idx = findfirst(occursin.(db_multi[:,"Search word"],text_name))
  return db_multi[idx,"System name"]
end
function restricted_distance_matrix(ii)
  key_words  = db_multi[ii,"Search word"]
  idx_keep = [any(occursin.(key_words, n)) for n in names(d_mat)]
  text_names = names(d_mat)[idx_keep]
  return d_mat[idx_keep,idx_keep], replace_names.(text_names)
end
# prepare the options for the various select inputs, using the data from the db
function movie_data(column)
  result = DBInterface.execute(db, "select distinct(`$column`) from movies") |> DataFrame
  c = String[]
  for entry in result[!,Symbol(column)]
    for e in split(entry, ',')
      push!(c, strip(e))
    end
  end
  pushfirst!(c |> unique! |> sort!, ALL)
end

# select the data from the db that matches the filters
function oscars(filters::Vector{<:String} = String[])
  query = "select * from movies where 1"
  for f in filters
    isempty(f) && continue
    query *= " and $f"
  end

  # @debug query

  DBInterface.execute(db, query) |> DataFrame
end

function filtered_systems()
  ## will eventually return a filtered version of db_multi
  return db_multi
end

# picks a random movie - should be replaced by the movie selected from the UI #TODO
function selected_movie()
  #result = DBInterface.execute(db, "select * from movies order by random() limit 1") |> DataFrame
  data = Dict{String,Any}()
  #for col in names(result)
  #  val = result[1,col]
  #  data[col] = isa(val, Missing) ? "" : val
  #end
  data
end

# checks if the filter is a value from db of placeholder "All"
function validvalue(filters::Vector{<:String})
  [endswith(f, "'%$(ALL)%'") || endswith(f, "'%%'") ? "" : f for f in filters]
end

# processes the plot's data based on filters
function plot_data()
  PlotData( x = (1:10),
            y = (1:10),
            plot = StipplePlotly.Charts.PLOT_TYPE_SCATTER
          )
end

function plot_data_MDS(mds_coord,text_names)
  PlotData(
      x = mds_coord[:,1],
      y = mds_coord[:,2],
      name = "number of casts",
      mode = "markers",
      text = text_names,
      plot = StipplePlotly.Charts.PLOT_TYPE_SCATTER
    )
end

function plot_layout(xtitle, ytitle)
  PlotLayout(
    xaxis = [PlotLayoutAxis(title = xtitle)],
    yaxis = [PlotLayoutAxis(xy = "y", title = ytitle)]#,
    #scaleanchor = "x"
  )
end

export Oscar

@reactive mutable struct Oscar <: ReactiveModel
  #filter_oscars::R{Int} = oscars_range.start
  #filter_years::R{RangeData{Int}} = RangeData(years_range.start:years_range.stop)
  #filter_country::R{String} = ALL
  #filter_genre::R{String} = ALL
  #filter_director::R{String} = ALL
  #filter_cast::R{String} = ALL
  #countries::Vector{<:String} = movie_data("Country")
  #genres::Vector{<:String} = movie_data("Genre")
  #genres::Vector{<:String} = movie_data("Country")
  #directors::Vector{<:String} = movie_data("Director")
  #directors::Vector{<:String} = movie_data("Country")
  #cast::Vector{<:String} = movie_data("Cast")
  
  movies::R{DataTable} = DataTable(oscars(), table_options)
  #movies_pagination::DataTablePagination = DataTablePagination(rows_per_page=50)
  #movies_selection::R{DataTableSelection} = DataTableSelection()

  multi_systems::R{DataTable} = DataTable(filtered_systems(),multi_table_options)
  multi_systems_pagination::DataTablePagination = DataTablePagination(rows_per_page=50)
  multi_systems_selection::R{DataTableSelection} = DataTableSelection()

  selected_movie::R{Dict} = selected_movie()
  data::R{Vector{PlotData}} = [plot_data()]
  layout::R{PlotLayout} = PlotLayout(plot_bgcolor = "#fff")
  
  
  one_way_traces::R{Vector{PlotData}} = [plot_data()]
  one_way_layout::R{PlotLayout} = PlotLayout(plot_bgcolor = "#fff")

  @mixin data::PlotlyEvents

  @mixin one_way_traces::PlotlyEvents
end

Stipple.js_mounted(::Oscar) = watchplots()

function handlers(model::Oscar)
  #onany(model.filter_oscars, model.filter_years, model.filter_country, model.filter_genre, model.filter_director, model.filter_cast, model.isready) do fo, fy, fc, fg, fd, fca, i
  onany(model.multi_systems_selection, model.isready) do msel, i
    model.isprocessing[] = true
   # model.movies[] = DataTable(String[
   #   "`Oscars` >= '$(fo)'",
   #   "`Year` between '$(fy.range.start)' and '$(fy.range.stop)'",
   #   "`Country` like '%$(fc)%'",
    #  "`Genre` like '%$(fg)%'",
    #  "`Director` like '%$(ALL)%'",
    #  "`Cast` like '%$(fca)%'"
    #] |> validvalue |> oscars, table_options)
    
    #model.one_way_traces[] = [plot_data_2()]
    ii = union(getindex.(msel, "__id"))
    if length(ii) == 0
      ii = 1:size(db_multi)[1]
    end
    d_mat_r, text_names = restricted_distance_matrix(ii)
    MDS_coords = permutedims(MultivariateStats.transform(MultivariateStats.fit(MDS,
        Matrix(d_mat_r), maxoutdim=3, distances=true)))
    #model.one_way_traces[] = [plot_data_2(model.multi_systems.data[ii,:])]
    model.data[] = [plot_data_MDS(MDS_coords[:,1:2],text_names)]
    model.one_way_traces[] = [plot_data_MDS(MDS_coords[:,2:3],text_names)]
    #model.one_way_layout[] = plot_layout("MDS PC1", "MDS PC2")
    model.layout[] = plot_layout("MDS PC1", "MDS PC2")
    model.one_way_layout[] = plot_layout("MDS PC2", "MDS PC3")
    model.isprocessing[] = false
  end

  #on(model.data_selected) do data
  #  selectrows!(model, :movies, getindex.(data["points"], "pointIndex") .+ 1)
  #end

  on(model.data_hover) do data
    return
  end

  model
end

end