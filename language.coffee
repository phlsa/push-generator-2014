window.Language = {}

Language.rawData = window.languageData
Language.defaultChar = [0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1]

# Normalize language data
Language.normalizedData = {}
_.each Language.rawData, (item, index) ->
  return if index is "languageName"
  maxFrequency = _.max(_.flatten(item))
  Language.normalizedData[index] = _.map item, (val, i) ->
    return val/maxFrequency

# Get frequencey values for a single char
Language.getChar = (char) ->
  c = Language.normalizedData[char]
  c = Language.defaultChar unless c?
  return c

