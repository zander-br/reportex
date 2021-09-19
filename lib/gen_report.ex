defmodule GenReport do
  alias GenReport.Parser

  @available_names [
    "cleiton",
    "daniele",
    "danilo",
    "diego",
    "giuliano",
    "jakeliny",
    "joseph",
    "mayk",
    "rafael",
    "vinicius"
  ]

  @available_months [
    "janeiro",
    "fevereiro",
    "março",
    "abril",
    "maio",
    "junho",
    "julho",
    "agosto",
    "setembro",
    "outubro",
    "novembro",
    "dezembro"
  ]

  def build(), do: {:error, "Insira o nome de um arquivo"}

  def build(filename) do
    filename
    |> Parser.parse_file()
    |> Enum.reduce(report_acc(), &sum_values/2)
  end

  def build_from_many(), do: {:error, "Insira os nomes dos arquivos"}

  def build_from_many(filenames) do
    filenames
    |> Task.async_stream(&build/1)
    |> Enum.reduce(report_acc(), fn {:ok, result}, report -> sum_reports(report, result) end)
  end

  defp sum_reports(report, result) do
    %{
      "all_hours" => all_hours1,
      "hours_per_month" => hours_per_month1,
      "hours_per_year" => hours_per_year1
    } = report

    %{
      "all_hours" => all_hours2,
      "hours_per_month" => hours_per_month2,
      "hours_per_year" => hours_per_year2
    } = result

    all_hours = merge_maps(all_hours1, all_hours2)
    hours_per_month = merge_nested_maps(hours_per_month1, hours_per_month2)
    hours_per_year = merge_nested_maps(hours_per_year1, hours_per_year2)

    build_report(all_hours, hours_per_month, hours_per_year)
  end

  defp merge_maps(map1, map2) do
    Map.merge(map1, map2, fn _key, value1, value2 -> value1 + value2 end)
  end

  defp merge_nested_maps(map1, map2) do
    Map.merge(map1, map2, fn _key, value1, value2 -> merge_maps(value1, value2) end)
  end

  defp sum_values(line, report) do
    [name, hours, _day, month, year] = line

    %{
      "all_hours" => all_hours,
      "hours_per_month" => hours_per_month,
      "hours_per_year" => hours_per_year
    } = report

    months = sum_values_in_map(hours_per_month[name], %{"key" => month, "value" => hours})
    years = sum_values_in_map(hours_per_year[name], %{"key" => year, "value" => hours})

    all_hours = Map.put(all_hours, name, all_hours[name] + hours)
    hours_per_month = Map.put(hours_per_month, name, months)
    hours_per_year = Map.put(hours_per_year, name, years)

    build_report(all_hours, hours_per_month, hours_per_year)
  end

  defp sum_values_in_map(map, %{"key" => key, "value" => value}) do
    Map.put(map, key, map[key] + value)
  end

  defp report_acc do
    months = Enum.into(@available_months, %{}, &{&1, 0})
    years = Enum.into(2016..2020, %{}, &{&1, 0})

    all_hours = Enum.into(@available_names, %{}, &{&1, 0})
    hours_per_month = Enum.into(@available_names, %{}, &{&1, months})
    hours_per_year = Enum.into(@available_names, %{}, &{&1, years})

    build_report(all_hours, hours_per_month, hours_per_year)
  end

  defp build_report(all_hours, hours_per_month, hours_per_year) do
    %{
      "all_hours" => all_hours,
      "hours_per_month" => hours_per_month,
      "hours_per_year" => hours_per_year
    }
  end
end
