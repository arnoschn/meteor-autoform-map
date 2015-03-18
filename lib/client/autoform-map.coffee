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
  @data.extractAddress = (place) ->
    city = state = country = zip = street = route = housenumber = false
    if not place.address:
      for i,ad in place.address_components
        if ad.types[0] == "locality"
          city = ad.long_name
        if ad.types[0] == "country"
          country = ad.long_name
        if ad.types[0] == "administrative_area_level_1"
          state = ad.long_name
        if ad.types[0] == "administrative_area_level_2"
          state = ad.long_name
        if ad.types[0] == "administrative_area_level_3"
          state = ad.long_name
        if ad.types[0] == "postal_code"
          zip = ad.long_name
        if ad.types[0] == "route"
          route = ad.long_name
        if ad.types[0] == "route"
          route = ad.long_name
        if ad.types[0] == "street_number"
          housenumber = ad.long_name
        if ad.types[0] =="street_address"
          street = ad.long_name
      if not street
        street = "#{route} #{housenumber}"
      {lat:place.geometry.location.lat(),lng:place.geometry.location.lng(),
        name: place.name, place_id:place.place_id,international_phone_number:place.international_phone_number,
        formatted_address:place.formatted_address,website:place.website,
        address:{city:city,state:state,country:country,zip:zip,street:street}}
    else
      place



  @data.setMarker = (map, place, zoom=0) =>
    data = @data.extractAddress(place)
    @$('.js-lat').val(data.lat)
    @$('.js-lng').val(data.lng)
    @$('.js-country').val(data.address.country)
    @$('.js-state').val(data.address.state)
    @$('.js-street').val(data.address.street)
    @$('.js-city').val(data.address.city)
    @$('.js-zip').val(data.address.zip)
    @$('.js-phone').val(data.international_phone_number)
    @$('.js-placeid').val(data.place_id)
    @$('.js-name').val(data.name)
    @$('.js-address').val(data.formatted_address)
    @$('.js-www').val(data.website)
    if @data.marker then @data.marker.setMap null
    @data.marker = new google.maps.Marker
      position: new google.maps.LatLng data.lat, data.lng
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
      @data.setMarker @data.map, @data.value, @data.options.zoom
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
