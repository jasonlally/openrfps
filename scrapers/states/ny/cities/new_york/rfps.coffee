# Require the necessary modules.
request = require 'request'
cheerio = require 'cheerio'
async = require 'async'
_ = require 'underscore'
require 'colors'

FORM_DATA =
  TON:1
  Alpha:true
  ProcurCat:0
  Type:'A'
  searchDescriptions:'yes'
  qryType:'all'

module.exports = (opts, done) ->

  rfps = []

  currentPage = 0

  getPage = (cb) ->
    currentPage += 1

    console.log "Getting page #{currentPage}"

    startPoint = if currentPage == 1
      null
    else if currentPage == 2
      0
    else
      (currentPage - 2) * 25

    request.post 'http://a856-internet.nyc.gov/nycvendoronline/vendorsearch/asp/Postings.asp',
      form: _.extend({ startPoint: startPoint}, FORM_DATA),
    , (err, response, body) ->
      console.log "Received page #{currentPage}".yellow
      $ = cheerio.load body

      $('h5.Hbox-blue').each ->
        rfps.push {
          title: $(@).next('h4').text()
        }

      console.log "Parsed page #{currentPage}".green

      if $('#A1').length > 0
        getPage(cb)
      else
        cb()

  getPage ->
    console.log 'All done!'.green
    done rfps
