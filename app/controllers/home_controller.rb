require 'rest-client'
require 'json'
require 'descriptive-statistics'
require 'date'

class HomeController < ApplicationController

	def index

		#======= Get Prameters =======

		@duration = params[:duration]	|| "30days"
		@amount = params[:amount] || 100


		#======= Get Bitcoin Data =======

		@url = "https://blockchain.info/charts/market-price?showDataPoints=false&timespan=%s&show_header=true&daysAverageString=1&scale=0&format=json&address=" % @duration

		response = RestClient.get @url
		@json_data = JSON.parse(response)['values']


		#======= Prepare data for Time Series Analysis =======

    timeseries_data = []
    timeseries_ave = []
    timeseries_hist = DescriptiveStatistics::Stats.new([0, 0, 0, 0, 0])
    timeseries_diff = []
		differential_data = []
		differential_ave = []
		forcast_diff = []
    @timeseries_record = []
    counter = 0
    prev_data = 0
		prev_ave = 0

		@json_data.each do |p|

			data = Hash.new
			data['date'] = Time.at(p['x']*1000)
			data['value'] = p['y']

			timeseries_hist.push(data['value'])
      timeseries_hist.shift(1)

			if counter > 4
				data['moving_ave'] = timeseries_hist.mean
			else
				data['moving_ave'] = data['value']
				prev_ave = data['value']
			end


			#----- Setup Array Data for Time Series Analysis -----

			timeseries_data.push([p['x']*1000, p['y']])

			#----- Setup Array Data for Differential Analysis -----

			if counter > 0
				timeseries_diff.push(data['value']-prev_data)
				differential_data.push([p['x']*1000, data['value']-prev_data])
			else
				timeseries_diff.push(0)
				differential_data.push([p['x']*1000, 0])
			end

			#----- Setup Array Data for Moving Average -----

      timeseries_ave.push([p['x']*1000, data['moving_ave']])
			differential_ave.push([p['x']*1000, data['moving_ave']-prev_ave])

			#----- Setup forcasting error -----

			forcast_diff.push(data['moving_ave'] - data['value'])

			@timeseries_record.push(data)
			counter = counter+1
			prev_data = data['value']
			prev_ave = data['moving_ave']
		end

		curr_rate = timeseries_hist[4]
		appreciation_rate = (curr_rate + differential_ave[counter-1][1]) / curr_rate


		#======= Prepare Data for Descriptive Statistics =======

		stats_data = DescriptiveStatistics::Stats.new(timeseries_hist)
		stats_diff = DescriptiveStatistics::Stats.new(timeseries_diff)
		stats_forcast = DescriptiveStatistics::Stats.new(forcast_diff)

		@desc_data = Hash.new
		@desc_diff = Hash.new

		@desc_data['number'] = timeseries_data.size
		@desc_diff['number'] = timeseries_diff.size
		@desc_data['mean'] = stats_data.mean
		@desc_diff['mean'] = stats_diff.mean
		@desc_data['std'] = stats_data.standard_deviation
		@desc_diff['std'] = stats_diff.standard_deviation
		@desc_data['min'] = stats_data.min
		@desc_diff['min'] = stats_diff.min
		@desc_data['max'] = stats_data.max
		@desc_diff['max'] = stats_diff.max
		@desc_data['range'] = stats_data.range
		@desc_diff['range'] = stats_diff.range


		#======= Prepare Data for Differential Analysis Result =======

		@result = Hash.new
		@result['latest_data'] = prev_data
		@result['latest_diff'] = differential_data[counter-1][1]
		@result['latest_diff_mv'] = differential_ave[counter-1][1]
		@result['appreciation_rate'] = appreciation_rate
		@result['forcast'] = prev_data * appreciation_rate
		@result['forcast_err_mean'] = stats_forcast.mean
		@result['forcast_err_std'] = stats_forcast.standard_deviation

		#======= Prepare Data for Break Even Point =======

    @bep_coinbase = []
		@bep_coinbase_adjusted = []
    @bep_coinbase_1std = []
    @bep_transferwise = []
    @bep_record = []

		(0..2000).step(100) {|amount|

			data = Hash.new
			data['amount'] = amount

			if amount < 5000
				data['transferwise'] = amount * 0.01 + 3
			else
				data['transferwise'] = 5000 * 0.01 + (amount - 5000) * 0.007 + 3
			end

			data['coinbase'] = amount * 0.02

			appreciation = (appreciation_rate - 1) * amount

			data['coinbase_adjusted'] = data['coinbase'] - appreciation
			data['coinbase_upper_1std'] = data['coinbase'] - appreciation + stats_forcast.standard_deviation / curr_rate * amount
			data['coinbase_lower_1std'] = data['coinbase'] - appreciation - stats_forcast.standard_deviation / curr_rate * amount
			data['coinbase_upper_2std'] = data['coinbase'] - appreciation + stats_forcast.standard_deviation / curr_rate * amount * 2
			data['coinbase_lower_2std'] = data['coinbase'] - appreciation - stats_forcast.standard_deviation / curr_rate * amount * 2

			if data['coinbase'] < data['transferwise']
				data['winner'] = 'Coinbase'
			else
				data['winner'] = 'Transferwise'
			end

			if data['coinbase_adjusted'] < data['transferwise']
				data['winner_adjusted'] = 'Coinbase'
			else
				data['winner_adjusted'] = 'Transferwise'
			end

			@bep_coinbase.push([amount, data['coinbase']])
			@bep_coinbase_adjusted.push([amount, data['coinbase_adjusted']])
			@bep_coinbase_1std.push([amount, data['coinbase_upper_1std'], data['coinbase_lower_1std']])
			@bep_transferwise.push([amount, data['transferwise']])
			@bep_record.push(data)
		}

		# comment out
=begin
		R.eval <<-EOF
			test<-as.numeric(1+1)
EOF
		@test = R.test
=end

		#======= Create Chart Data for Time Series Analysis =======

		@timeseries_chart = LazyHighCharts::HighChart.new('graph') do |f|
      f.title(text: "The Market Price of Bitcoin")
      f.subtitle(text: "source: blockchain.info")
      f.xAxis(type: 'datetime')
      f.yAxis [
        {title: {text: "Value [USD]"}, showFirstLabel: false },
 ]
      f.legend(align: 'right', verticalAlign: 'top', y: 75, x: -50, layout: 'vertical',)
      f.plotOptions(line: {
        marker: {
          radius: 0
        },
        lineWidth: 1,
        states: {
          hover: {
            lineWidth: 1
          }
        }
      })
      f.series(
        name: "Actual Data",
        yAxis: 0,
        data: timeseries_data
      )
			f.series(
				name: "Moving Average (5)",
				yAxis: 0,
				lineWidth: 2,
				data: timeseries_ave
			)
      f.chart({:defaultSeriesType=>"line"})
    end

		#======= Create Chart Data for Differential Analysis =======

		@diff_chart = LazyHighCharts::HighChart.new('graph') do |f|
      f.title(text: "The Differential of Bitcoin")
      f.subtitle(text: "source: blockchain.info")
      f.xAxis(type: 'datetime')
      f.yAxis [
        {title: {text: "Value [USD]"}, showFirstLabel: false },
 ]
      f.legend(align: 'right', verticalAlign: 'top', y: 75, x: -50, layout: 'vertical',)
      f.plotOptions(line: {
        marker: {
          radius: 0
        },
        lineWidth: 1,
        states: {
          hover: {
            lineWidth: 1
          }
        }
      })
      f.series(
        name: "Actual Data",
        yAxis: 0,
        data: differential_data
      )
			f.series(
        name: "Moving Average(5)",
        yAxis: 0,
				lineWidth: 2,
        data: differential_ave
      )
			f.chart({:defaultSeriesType=>"line"})
    end


		#======= Create Chart Data for Break Even Analysis

    @bep_chart = LazyHighCharts::HighChart.new('graph') do |f|
      f.title(text: "Break Even Point between Coinbase and Transferwise")
      f.xAxis({title: {text: "Amount [USD]"}, type: 'number'})
      f.yAxis [
        {title: {text: "Fee [USD]"}, showFirstLabel: false },
 ]
      f.legend(align: 'right', verticalAlign: 'top', y: 75, x: -50, layout: 'vertical',)
      f.plotOptions(line: {
        marker: {
          radius: 0
        },
        lineWidth: 1,
        states: {
          hover: {
            lineWidth: 1
          }
        }
      })
      f.series(
        name: "Coinbase",
        data: @bep_coinbase,
        lineWidth: 2
      )
      f.series(
        name: "Transferwise",
        data: @bep_transferwise,
        lineWidth: 2
      )
      f.chart({:defaultSeriesType=>"line"})
    end

		@bep_chart_confidence = LazyHighCharts::HighChart.new('graph') do |f|
			f.title(text: "Adjusted Break Even Point with time trend of Bitcoin exchange rate")
			f.xAxis({title: {text: "Amount [USD]"}, type: 'number'})
			f.yAxis [
        {title: {text: "Fee [USD]"}, showFirstLabel: false },
 ]
			f.legend(align: 'right', verticalAlign: 'top', y: 75, x: -50, layout: 'vertical',)
			f.plotOptions(line: {
				marker: {
					radius: 0
				},
				lineWidth: 1,
				states: {
					hover: {
						lineWidth: 1
					}
				}
			})
			f.series(
				name: "Coinbase", 
				data: @bep_coinbase,
				lineWidth: 2
			)
			f.series(
				name: "Transferwise",
				data: @bep_transferwise,
				lineWidth: 2
			)
      f.series(
        name: "Coinbase (adjusted with bitcoin's appreciation)",
        data: @bep_coinbase_adjusted,
				lineWidth: 2
      )
			f.series(
        name: "Coinbase (adjusted with bitcoin's appreciation and 1STD range)",
        data: @bep_coinbase_1std,
				type: 'arearange',
				color: '#00ff00',
				fillOpacity: 0.3,
        zIndex: 0
      )
			f.chart({:defaultSeriesType=>"line"})
		end
	end
end
