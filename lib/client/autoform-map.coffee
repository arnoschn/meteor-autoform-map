KEY_ENTER = 13

defaults =
  mapType: 'roadmap'
  mapId:  'afMap'
  defaultLat: 1
  defaultLng: 1
  geolocation: false
  searchBox: false
  autolocate: false
  zoom: 13

AutoForm.addInputType 'map',
  template: 'afMap'
  valueOut: ->
    node = $(@context)

    lat: node.find('.js-lat').val()
    lng: node.find('.js-lng').val()
    country:node.find('.js-country').val()
    state:node.find('.js-state').val()
    street:node.find('.js-street').val()
    city:node.find('.js-city').val()
    zip:node.find('.js-zip').val()
    phone:node.find('.js-phone').val()
    placeid:node.find('.js-placeid').val()
    name:node.find('.js-name').val()
    address:node.find('.js-address').val()
    website:node.find('.js-www').val()
  contextAdjust: (ctx) ->
    ctx.loading = new ReactiveVar(false)
    ctx
  valueConverters:
    string: (value) ->
      "#{value.lat},#{value.lng}"

Template.afMap.rendered = ->
  @data.options = _.extend {}, defaults, @data.atts

  @data.marker = undefined
  @data.setMarker = (map, place, zoom=0) =>
    @$('.js-lat').val(place.geometry.location.lat())
    @$('.js-lng').val(place.geometry.location.lng())
    @$('.js-country').val(place.geometry.location.lng())
    @$('.js-state').val(place.geometry.location.lng())
    @$('.js-street').val(place.geometry.location.lng())
    @$('.js-city').val(place.geometry.location.lng())
    @$('.js-zip').val(place.geometry.location.lng())
    @$('.js-phone').val(place.international_phone_number)
    @$('.js-placeid').val(place.place_id)
    @$('.js-name').val(place.name)
    @$('.js-address').val(place.formatted_address)
    @$('.js-www').val(place.website)
    if @data.marker then @data.marker.setMap null
    @data.marker = new google.maps.Marker
      position: place.geometry.location
      map: map

    if zoom > 0
      @data.map.setZoom zoom

  GoogleMaps.init { libraries: 'places' }

  GoogleMaps.ready @data.atts.mapId, (map) =>
    mapOptions =
      zoom: 0
      mapId: @data.options.mapId
      mapTypeId: google.maps.MapTypeId[@data.options.mapType]
      streetViewControl: false

    if @data.atts.googleMap
      _.extend mapOptions, @data.atts.googleMap

    @data.map = map

    if @data.value
      location = if typeof @data.value == 'string' then @data.value.split ',' else [@data.value.lat, @data.value.lng]
      location = new google.maps.LatLng parseFloat(location[0]), parseFloat(location[1])
      @data.setMarker @data.map, location, @data.options.zoom
      @data.map.setCenter location
    else
      @data.map.setCenter new google.maps.LatLng @data.options.defaultLat, @data.options.defaultLng

    if @data.atts.searchBox
      input = @find('.js-search')

      @data.map.controls[google.maps.ControlPosition.TOP_LEFT].push input
      searchBox = new google.maps.places.SearchBox input

      google.maps.event.addListener searchBox, 'places_changed', =>
        place = searchBox.getPlaces()[0]
        @data.setMarker @data.map, place
        @data.map.setCenter place.geometry.location

      $(input).removeClass('af-map-search-box-hidden')

    if @data.atts.autolocate and navigator.geolocation and not @data.value
      navigator.geolocation.getCurrentPosition (position) =>
        location = new google.maps.LatLng position.coords.latitude, position.coords.longitude
        @data.setMarker @data.map, location, @data.options.zoom
        @data.map.setCenter location

    if typeof @data.atts.rendered == 'function'
      @data.atts.rendered @data.map

    google.maps.event.addListener @data.map, 'click', (e) =>
      @data.setMarker @data.map, e.latLng

  @$('.js-map').closest('form').on 'reset', =>
    @data.marker.setMap null
    @data.map.setCenter new google.maps.LatLng @data.options.defaultLat, @data.options.defaultLng
    @data.map.setZoom 0

Template.afMap.helpers
  mapOptions: ->
    mapOptions =
      zoom: 0
      mapId: @atts.mapId
      mapTypeId: google.maps.MapTypeId[@atts.mapType]
      streetViewControl: false

    if @atts.googleMap
      _.extend mapOptions, @atts.googleMap

    mapOptions

  schemaKey: ->
    @atts['data-schema-key']
  width: ->
    if typeof @atts.width == 'string'
      @atts.width
    else if typeof @atts.width == 'number'
      @atts.width + 'px'
    else
      '100%'
  height: ->
    if typeof @atts.height == 'string'
      @atts.height
    else if typeof @atts.height == 'number'
      @atts.height + 'px'
    else
      '200px'
  mapId: ->
    @atts.mapId
  loading: ->
    @loading.get()

Template.afMap.events
  'click .js-locate': (e, t) ->
    e.preventDefault()

    unless navigator.geolocation then return false

    @loading.set true
    navigator.geolocation.getCurrentPosition (position) =>
      location = new google.maps.LatLng position.coords.latitude, position.coords.longitude
      @setMarker @map, location, @options.zoom
      @map.setCenter location
      @loading.set false

  'keydown .js-search': (e) ->
    if e.keyCode == KEY_ENTER then e.preventDefault()
