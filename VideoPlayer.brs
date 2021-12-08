'''''''''
' init: VideoPlayer component example that implements trick play through a Poster component
'       Extends default Video component
' 
'''''''''
sub init()
    m.poster = createObject("roSGNode", "Poster")

    m.top.observeFieldScoped("thumbnailTiles", "initTrickPlay")
    m.top.observeFieldScoped("thumbnails", "onGetThumbnails")
    m.top.observeFieldScoped("position", "onPositionChange")
end sub

'''''''''
' initTrickPlay: Finds and sets thumbnail data to field
'                First step in initializing trick play
'
' @param {object} event
'''''''''
sub initTrickPlay(event as object)
    thumbnailsData = event.getData()
    if thumbnailsData = invalid or thumbnailsData.count() < 1 then return

    thumbnails = invalid
    for each size in thumbnailsData
        if size <> invalid and thumbnailsData[size] <> invalid and thumbnailsData[size][0] <> invalid then
            thumbnails = thumbnailsData[size][0]
            exit for
        end if
    end for

    m.top.thumbnails = thumbnails
end sub

'''''''''
' onGetThumbnails: Initializes the poster in relation to thumbnail data
' 
'''''''''
sub onGetThumbnails(event as object)
    thumbnails = event.getData()
    if thumbnails = invalid or thumbnails.width = invalid or thumbnails.height = invalid or thumbnails.htiles = invalid or thumbnails.vtiles = invalid then
        return
    end if

    m.top.posterWidth = thumbnails.width
    m.top.posterHeight = thumbnails.height

    m.poster.loadWidth = m.top.posterWidth * thumbnails.htiles
    m.poster.loadHeight = m.top.posterHeight * thumbnails.vtiles
end sub

'''''''''
' onPositionChange: Fires when the position field is updated
'                   Updates poster to display corresponding thumbnail image based on position
' 
' @param {object} event
'''''''''
sub onPositionChange(event as object)
    position = event.getData()
    if position = invalid then return

    spriteIndex = getSpriteIndex(position)
    if spriteIndex < 0 then return

    rowColumnIndex = getRowColumnIndex(position, spriteIndex)
    m.poster.clippingRect = getClippingRect(rowColumnIndex.columnIndex, rowColumnIndex.rowIndex)
    m.poster.translation = getPosterTranslation(rowColumnIndex.columnIndex, rowColumnIndex.rowIndex)
    m.poster.uri = getPosterUri(spriteIndex)
end sub

'''''''''
' getSpriteIndex: Returns the sprite sheet index according to the position requested
'                 This is needed in order to find the appropriate thumbnail tile
'                 Which means finding the row and column indexes within the sprite sheet based on position requested
' 
' @param {double} [position=0]
' @return {integer}
'''''''''
function getSpriteIndex(position = 0 as double) as integer
    if m.top.thumbnails = invalid or m.top.thumbnails.tiles = invalid or position < 0 or position > m.top.duration then return -1

    for i = 0 to m.top.thumbnails.tiles.count() - 1
        currentSpriteSheet = m.top.thumbnails.tiles[i]
        nextSpriteSheet = invalid

        if (i + 1) < m.top.thumbnails.tiles.count()
            nextSpriteSheet = m.top.thumbnails.tiles[i + 1]
        end if

        currentSpriteSheetStartTime = currentSpriteSheet[1]
        if position >= currentSpriteSheetStartTime
            if nextSpriteSheet <> invalid
                nextSpriteSheetStartTime = nextSpriteSheet[1]
                if position < nextSpriteSheetStartTime
                    return i
                end if
            else
                return i
            end if
        else
            return i - 1
        end if
    end for

    return -1
end function

'''''''''
' getRowColumnIndex: Returns the row and column index corresponding to the position requested
'                    We have to pass sprite index to know what poster to start looking up the row and column indexes from.
' 
' @param {double} [position=0]
' @param {integer} [spriteIndex=0]
' @return {object}
'''''''''
function getRowColumnIndex(position = 0 as double, spriteIndex = 0 as integer) as object
    tileDuration = m.top.thumbnails.duration / (m.top.thumbnails.vtiles * m.top.thumbnails.htiles)
    currentSpriteSheetStartTime = m.top.thumbnails.tiles[spriteIndex][1]
    nextSpriteSheetStartTime = invalid

    rowIndex = 0
    columnIndex = 0
    exitForLoop = false

    for i = 0 to m.top.thumbnails.vtiles - 1
        for j = 0 to m.top.thumbnails.htiles - 1
            if position >= (currentSpriteSheetStartTime + (((i * m.top.thumbnails.htiles) + j) * tileDuration))
                if position < (currentSpriteSheetStartTime + (((i * m.top.thumbnails.htiles) + j + 1) * tileDuration))
                    rowIndex = i
                    columnIndex = j
                    exitForLoop = true
                    exit for
                end if
            end if
        end for

        if exitForLoop then exit for
    end for

    return {
        rowIndex: rowIndex
        columnIndex: columnIndex
    }
end function

'''''''''
' getClippingRect: Returns the sprite sheet cropping rectangle based on row/column
' 
' @param {integer} [columnIndex=0]
' @param {integer} [rowIndex=0]
' @return {object}
'''''''''
function getClippingRect(columnIndex = 0 as integer, rowIndex = 0 as integer) as object
    x = columnIndex * m.top.posterWidth
    y = rowIndex * m.top.posterHeight
    width = m.top.posterWidth
    height = m.top.posterHeight

    return [x, y, width, height]
end function

'''''''''
' getPosterTranslation: Returns the sprite sheet translation based on row/column
' 
' @param {integer} [columnIndex=0]
' @param {integer} [rowIndex=0]
' @return {object}
'''''''''
function getPosterTranslation(columnIndex = 0 as integer, rowIndex = 0 as integer) as object
    x = 0 - (m.top.posterWidth * columnIndex)
    y = 0 - (m.top.posterHeight * rowIndex)

    return [x, y]
end function

'''''''''
' getPosterUri: Returns the sprite sheet by index
' 
' @param {integer} [spriteIndex=0]
' @return {string}
'''''''''
function getPosterUri(spriteIndex = 0 as integer) as string
    if m.top.thumbnails = invalid or m.top.thumbnails.tiles = invalid or m.top.thumbnails.tiles[spriteIndex] = invalid or m.top.thumbnails.tiles[spriteIndex][0] = invalid then
        return ""
    end if

    return m.top.thumbnails.tiles[spriteIndex][0]
end function