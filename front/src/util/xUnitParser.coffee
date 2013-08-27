'use strict'

getAttribute = (testCaseString, attributeName) ->
    assert.ok typeof testCaseString is 'string'
    assert.ok typeof attributeName is 'string'

    nameStartIndex = testCaseString.indexOf(" #{attributeName}=\"") + "#{attributeName}=\"".length + 1
    nameEndIndex = testCaseString.indexOf '"', nameStartIndex

    return testCaseString.substring nameStartIndex, nameEndIndex

extractTextFromCData = (text) ->
    assert.ok typeof text is 'string'

    cDataStartTag = '<![CDATA['
    cDataEndTag = ']]>'

    return text if text.indexOf(cDataStartTag) is -1 or text.indexOf(cDataEndTag) is -1

    textStartIndex = text.indexOf(cDataStartTag) + cDataStartTag.length
    textEndIndex = text.indexOf cDataEndTag

    return text.substring textStartIndex, textEndIndex

getTextInElement = (testCaseString, elementName) ->
    assert.ok typeof testCaseString is 'string'
    assert.ok typeof elementName is 'string'

    elementStartIndex = testCaseString.indexOf("<#{elementName}")
    return null if elementStartIndex is -1

    textStartIndex = testCaseString.indexOf('>', elementStartIndex) + 1
    textEndIndex = testCaseString.indexOf("</#{elementName}>", textStartIndex)

    text = testCaseString.substring textStartIndex, textEndIndex
    return extractTextFromCData text

getTestCaseString = (xunitOutput, startIndex) ->
    assert.ok typeof xunitOutput is 'string'
    assert.ok typeof startIndex is 'number'

    testCaseStartTag = '<testcase '
    testCaseEndTag = '</testcase>'
    testCaseSelfClose = '/>'

    testCaseStartIndex = xunitOutput.indexOf testCaseStartTag, startIndex
    return null if testCaseStartIndex is -1

    testCaseClosingTagIndex = xunitOutput.indexOf testCaseEndTag, testCaseStartIndex
    testCaseSelfClosingTagIndex = xunitOutput.indexOf testCaseSelfClose, testCaseStartIndex

    testCaseEndIndex = null
    if testCaseSelfClosingTagIndex isnt -1 and testCaseClosingTagIndex is -1
        testCaseEndIndex = testCaseSelfClosingTagIndex + testCaseSelfClose.length
    else if testCaseSelfClosingTagIndex is -1 and testCaseClosingTagIndex isnt -1
        testCaseEndIndex = testCaseClosingTagIndex + testCaseEndTag.length
    else if testCaseSelfClosingTagIndex isnt -1 and testCaseClosingTagIndex isnt -1
        testCaseEndIndex = Math.min testCaseSelfClosingTagIndex + testCaseSelfClose.length,
            testCaseClosingTagIndex + testCaseEndTag.length
    else
        throw 'Nonexistent closing tag'

    toReturn =
        start: testCaseStartIndex
        end: testCaseEndIndex
        text: xunitOutput.substring testCaseStartIndex, testCaseEndIndex
    return toReturn

window.xUnitParse = (xunitOutput) ->
    assert.ok typeof xunitOutput is 'string'
    
    currentTestCaseString = getTestCaseString xunitOutput, 0

    testCases = []
    while currentTestCaseString?
        testCase =
            name: getAttribute currentTestCaseString.text, 'name'
            time: Number getAttribute currentTestCaseString.text, 'time'
            failure: getTextInElement currentTestCaseString.text, 'failure'
            error: getTextInElement currentTestCaseString.text, 'system-err'
        testCase.status = if testCase.failure? then 'failed' else 'passed'

        testCases.push testCase
        currentTestCaseString = getTestCaseString xunitOutput, currentTestCaseString.end

    return testCases
