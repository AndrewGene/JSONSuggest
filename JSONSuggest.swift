//
//  JSONSuggest.swift
//  JSONSuggest
//
//  Created by Andrew Goodwin on 9/15/16.
//  Copyright © 2016 Andrew Goodwin. All rights reserved.
//

import Foundation

public class JSONSuggest{
    static var sharedSuggest = JSONSuggest()
    var classList = [SuggestClass]()
    var swiftVersion = "2"
    var singleFile = false
    var includeSerialization = true
    var includeDeserialization = true
    var ignoreImplementedClasses = false
    var defaultValues:[String:String] = ["String":"\"\"", "Int": "-1", "Double":"-1.0","Bool":"false"]
    var deliveryMethod:DeliveryMethod = .FileSystem
    var saveDirectory = "/Users/<your_username_here>/Desktop"
    //var saveDirectory = "$HOME/Desktop"
    var isDebug = true //you can set this to false when you release and it will not run
    
    var classOrder = [String]()
    
    var numberOfLinesGenerated = 0
    
    private var currentClass:SuggestClass? = nil
    
    private init(){
        
    }
    
    func hasClass(name:String)->Bool{
        return self.classList.filter({$0.className == name}).count > 0
    }
    
    func makeSuggestions(JSON:AnyObject){
        makeSuggestions(JSON, root: "Root")
    }
    
    func makeSuggestions(JSON:AnyObject, root:String){
        if isDebug{
            if deliveryMethod == .FileSystem && (saveDirectory == "" || saveDirectory == "/Users/<your_username_here>/Desktop"){
                print("To save to the file system, please set the .saveDirectory property. Try something like \"/Users/<your_username_here>/Desktop\".")
                print("")
                print("❕Hint: open the Console app and type...")
                print("")
                print("echo $USER")
                print("")
                print("...to see your username ❕")
            }
            else if deliveryMethod == .FileSystem && (saveDirectory.hasPrefix("~") || saveDirectory.hasPrefix("$")){
                print("Save directory cannot contain aliases. Try something like \"/Users/<your_username_here>/Desktop\".")
                print("")
                print("❕Hint: open the Console app and type...")
                print("")
                print("echo $USER")
                print("")
                print("...to see your username❕")
            }
            else{
                if JSON is [String:AnyObject]{
                    if (JSON as! [String:AnyObject]).values.count > 0{
                        if (JSON as! [String:AnyObject]).values.first is [String:AnyObject]{
                            //print("good to go")
                        }
                        else{
                            //print("found simple type")
                            let newClass = SuggestClass(className: root)
                            classList.append(newClass)
                            currentClass = newClass
                        }
                    }
                    traverseDictionary((JSON as! [String:AnyObject]))
                }
                else if JSON is [[String:AnyObject]]{
                    let newClass = SuggestClass(className: root)
                    classList.append(newClass)
                    currentClass = newClass
                    traverseArray(JSON as! [[String:AnyObject]])
                }
                determineOptionals()
                if deliveryMethod == .URL || deliveryMethod == .FileSystem{
                    writeList()
                }
                else{
                    printList()
                }
            }
        }
    }
    
    private func determineOptionals(){
        for cls in classList{
            for property in cls.properties{
                if !property.isOptional{
                    if property.instances < cls.instances{
                        property.isOptional = true
                    }
                }
            }
        }
    }
    
    private func determineSimpleProperty(k:String,v:AnyObject){
        //TODO: add NSDate and [NSDate]
        if v is [String]{
            if currentClass != nil{
                if !currentClass!.hasProperty(k){
                    let suggestProperty = SuggestProperty()
                    suggestProperty.name = k
                    suggestProperty.type = "[String]"
                    
                    for str in v as! [String]{
                        if str != ""{
                            suggestProperty.canBeReplaced = false
                            break
                        }
                    }
                    if currentClass!.subClasses.filter({$0.className == suggestProperty.name}).count == 0{
                        currentClass!.properties.append(suggestProperty)
                    }
                }
                else{
                    let suggestProperty = currentClass!.properties.filter({$0.name == k}).first!
                    suggestProperty.instances += 1
                    if suggestProperty.canBeReplaced{
                        for str in v as! [String]{
                            if str != ""{
                                suggestProperty.canBeReplaced = false
                                break
                            }
                        }
                        suggestProperty.type = "[String]"
                    }
                }
            }
        }
        if v is [Bool]{
            if currentClass != nil{
                if !currentClass!.hasProperty(k){
                    let suggestProperty = SuggestProperty()
                    suggestProperty.name = k
                    suggestProperty.type = "[Bool]"
                    
                    for str in v as! [Bool]{
                        if "\(str)" == "1" || "\(str)" == "0" || "\(str)" == "true" || "\(str)" == "false"{
                            suggestProperty.canBeReplaced = false
                            break
                        }
                    }
                    
                    if currentClass!.subClasses.filter({$0.className == suggestProperty.name}).count == 0{
                        currentClass!.properties.append(suggestProperty)
                    }
                }
                else{
                    let suggestProperty = currentClass!.properties.filter({$0.name == k}).first!
                    suggestProperty.instances += 1
                    if suggestProperty.canBeReplaced{
                        for str in v as! [Bool]{
                            if "\(str)" == "1" || "\(str)" == "0" || "\(str)" == "true" || "\(str)" == "false"{
                                suggestProperty.canBeReplaced = false
                                break
                            }
                        }
                        suggestProperty.type = "[Bool]"
                    }
                }
            }
        }
        if v is [Double]{
            if currentClass != nil{
                if !currentClass!.hasProperty(k){
                    let suggestProperty = SuggestProperty()
                    suggestProperty.name = k
                    suggestProperty.type = "[Double]"
                    
                    for str in v as! [Double]{
                        if ("\(str)").containsString("."){
                            suggestProperty.canBeReplaced = false
                            break
                        }
                    }
                    
                    if currentClass!.subClasses.filter({$0.className == suggestProperty.name}).count == 0{
                        currentClass!.properties.append(suggestProperty)
                    }
                }
                else{
                    let suggestProperty = currentClass!.properties.filter({$0.name == k}).first!
                    suggestProperty.instances += 1
                    if suggestProperty.canBeReplaced{
                        for str in v as! [Double]{
                            if ("\(str)").containsString("."){
                                suggestProperty.canBeReplaced = false
                                break
                            }
                        }
                        suggestProperty.type = "[Double]"
                    }
                }
            }
        }
        if v is [Int]{
            if currentClass != nil{
                if !currentClass!.hasProperty(k){
                    let suggestProperty = SuggestProperty()
                    suggestProperty.name = k
                    suggestProperty.type = "[Int]"
                    
                    for str in v as! [Int]{
                        if !("\(str)").containsString(".") && str != 0 && str != 1{
                            suggestProperty.canBeReplaced = false
                            break
                        }
                    }
                    
                    if currentClass!.subClasses.filter({$0.className == suggestProperty.name}).count == 0{
                        currentClass!.properties.append(suggestProperty)
                    }
                }
                else{
                    let suggestProperty = currentClass!.properties.filter({$0.name == k}).first!
                    suggestProperty.instances += 1
                    if suggestProperty.canBeReplaced{
                        for str in v as! [Int]{
                            if !("\(str)").containsString(".") && str != 0 && str != 1{
                                suggestProperty.canBeReplaced = false
                                break
                            }
                        }
                        suggestProperty.type = "[Int]"
                    }
                }
            }
        }
        if v is String{
            if currentClass != nil{
                if !currentClass!.hasProperty(k){
                    let suggestProperty = SuggestProperty()
                    suggestProperty.name = k
                    suggestProperty.type = "String"
                    if v as! String != ""{
                        suggestProperty.canBeReplaced = false
                    }
                    if currentClass!.subClasses.filter({$0.className == suggestProperty.name}).count == 0{
                        currentClass!.properties.append(suggestProperty)
                    }
                }
                else{
                    let suggestProperty = currentClass!.properties.filter({$0.name == k}).first!
                    suggestProperty.instances += 1
                    if suggestProperty.canBeReplaced{
                        if v as! String != ""{
                            suggestProperty.canBeReplaced = false
                            suggestProperty.type = "String"
                        }
                    }
                }
            }
        }
        if v is Bool{
            if currentClass != nil{
                if !currentClass!.hasProperty(k){
                    let suggestProperty = SuggestProperty()
                    suggestProperty.name = k
                    suggestProperty.type = "Bool"
                    if "\(v)" == "1" || "\(v)" == "0" || "\(v)" == "true" || "\(v)" == "false"{
                        suggestProperty.canBeReplaced = false
                    }
                    if currentClass!.subClasses.filter({$0.className == suggestProperty.name}).count == 0{
                        currentClass!.properties.append(suggestProperty)
                    }
                }
                else{
                    let suggestProperty = currentClass!.properties.filter({$0.name == k}).first!
                    suggestProperty.instances += 1
                    if suggestProperty.canBeReplaced{
                        if "\(v)" == "1" || "\(v)" == "0" || "\(v)" == "true" || "\(v)" == "false"{
                            suggestProperty.canBeReplaced = false
                            suggestProperty.type = "Bool"
                        }
                    }
                }
            }
        }
        if v is Double{
            if currentClass != nil{
                if !currentClass!.hasProperty(k){
                    let suggestProperty = SuggestProperty()
                    suggestProperty.name = k
                    suggestProperty.type = "Double"
                    if "\(v)".containsString("."){
                        suggestProperty.canBeReplaced = false
                    }
                    if currentClass!.subClasses.filter({$0.className == suggestProperty.name}).count == 0{
                        currentClass!.properties.append(suggestProperty)
                    }
                }
                else{
                    let suggestProperty = currentClass!.properties.filter({$0.name == k}).first!
                    suggestProperty.instances += 1
                    if suggestProperty.canBeReplaced{
                        if "\(v)".containsString("."){
                            suggestProperty.canBeReplaced = false
                            suggestProperty.type = "Double"
                        }
                    }
                }
            }
        }
        if v is Int{
            if currentClass != nil{
                if !currentClass!.hasProperty(k){
                    let suggestProperty = SuggestProperty()
                    suggestProperty.name = k
                    suggestProperty.type = "Int"
                    if !"\(v)".containsString(".") && (v as! Int) != 0 && (v as! Int) != 1{
                        suggestProperty.canBeReplaced = false
                    }
                    if currentClass!.subClasses.filter({$0.className == suggestProperty.name}).count == 0{
                        currentClass!.properties.append(suggestProperty)
                    }
                }
                else{
                    let suggestProperty = currentClass!.properties.filter({$0.name == k}).first!
                    suggestProperty.instances += 1
                    if suggestProperty.canBeReplaced{
                        if !"\(v)".containsString(".") && (v as! Int) != 0 && (v as! Int) != 1{
                            suggestProperty.canBeReplaced = false
                            suggestProperty.type = "Int"
                        }
                    }
                }
            }
        }
        if v is NSNull{
            if currentClass != nil{
                if !currentClass!.hasProperty(k){
                    let suggestProperty = SuggestProperty()
                    suggestProperty.name = k
                    suggestProperty.type = "UNDEFINED"
                    suggestProperty.canBeReplaced = true
                    suggestProperty.isOptional = true
                    if currentClass!.subClasses.filter({$0.className == suggestProperty.name}).count == 0{
                        currentClass!.properties.append(suggestProperty)
                    }
                }
            }
        }
    }
    
    private func traverseDictionary(JSON:[String:AnyObject]){
        for (k,v) in JSON{
            if v is [String:AnyObject]{
                let filtered = classList.filter({$0.className == k})
                if filtered.count > 0 && currentClass != nil && currentClass!.isFromArray{
                    let theClass = filtered.first!
                    classOrder.append(theClass.className)
                }
                else{
                    let newClass = SuggestClass(className: k)
                    if classList.filter({$0.className == newClass.className}).count == 0{
                        let parse = SuggestToParse()
                        parse.key = k
                        parse.value = v as! [String:AnyObject]
                        newClass.toParse.append(parse)
                        classList.append(newClass)
                        
                        if currentClass != nil{                            
                            let propertyThatShouldBeClass = currentClass!.properties.filter({$0.name == newClass.className})
                            if propertyThatShouldBeClass.count > 0{
                                let theProperty = propertyThatShouldBeClass.first!
                                currentClass!.properties = currentClass!.properties.filter({$0.name != theProperty.name})
                            }
                            
                            if currentClass!.subClasses.filter({$0.className == newClass.className}).count == 0{
                                newClass.isOptional = true
                                currentClass!.subClasses.append(newClass) //display purposes only
                            }
                        }
                    }
                }
                
            }
            if v is [[String:AnyObject]]{
                let suggestProperty = SuggestProperty()
                suggestProperty.name = k
                if (v as! [[String:AnyObject]]).count > 0{
                    suggestProperty.canBeReplaced = false
                }
                var propertyType = "[\(k)]"
                if k.hasSuffix("s"){
                    propertyType = "[\(k.substringToIndex(k.endIndex.predecessor()))]"
                }
                suggestProperty.type = propertyType
                if (currentClass != nil && !currentClass!.hasProperty(k)){
                    currentClass!.properties.append(suggestProperty)
                }
                else if currentClass != nil{
                    suggestProperty.instances += 1 //count number of times this property has shown up, if it's less that total times the class is seen then it's optional
                }
                
                let newClass = SuggestClass(className: propertyType.stringByReplacingOccurrencesOfString("[", withString: "").stringByReplacingOccurrencesOfString("]", withString: ""))
                if classList.filter({$0.className == newClass.className}).count == 0{
                    newClass.isFromArray = true
                    if (v as! [[String:AnyObject]]).count > 0{
                        let parse = SuggestToParse()
                        parse.key = k
                        parse.value = v as! [[String : AnyObject]]
                        newClass.toParse.append(parse)
                    }

                    newClass.maxIterations = (v as! [[String:AnyObject]]).count

                    classList.append(newClass)
                }
                else{
                    let filtered = classList.filter({$0.className == propertyType.stringByReplacingOccurrencesOfString("[", withString: "").stringByReplacingOccurrencesOfString("]", withString: "")})
                    if filtered.count > 0 && currentClass != nil && currentClass!.isFromArray{
                        let theClass = filtered.first!

                        if (v as! [[String:AnyObject]]).count > 0{
                            let parse = SuggestToParse()
                            parse.key = k
                            parse.value = v as! [[String : AnyObject]]
                            theClass.toParse.append(parse)
                        }

                        theClass.maxIterations = (v as! [[String:AnyObject]]).count
                    }
                }
                
            }
            determineSimpleProperty(k, v: v)
        }
        
      
        if currentClass != nil && currentClass!.isFromArray{
            currentClass!.instances += 1
            currentClass!.iterations += 1
            if currentClass!.iterations == currentClass!.maxIterations{
                currentClass!.iterations = 0 //reset
                currentClass!.maxIterations = 1 //reset
      
                currentClass = nil
                for cl in classList{
                    let notStarted = cl.toParse.filter({!$0.started}).count
                    if notStarted > 0{
                        currentClass = cl
                        classOrder.append(currentClass!.className)
                        break
                    }
                }
                
                if currentClass != nil{
                    for tp in currentClass!.toParse{
                        if !tp.started{
                            if tp.value is [String:AnyObject]{
                                tp.started = true
                                traverseDictionary(tp.value as! [String:AnyObject])
                            }
                            else{
                                tp.started = true
                                traverseArray(tp.value as! [[String:AnyObject]])
                            }
                        }
                    }
                }
            }
            else{
                //continue
            }
        }
        else{
            currentClass = nil
            for cl in classList{
                let notStarted = cl.toParse.filter({!$0.started}).count
                if notStarted > 0{
                    currentClass = cl
                    classOrder.append(currentClass!.className)
                    break
                }
            }
            
            if currentClass != nil{
                for tp in currentClass!.toParse{
                    if !tp.started{
                        if tp.value is [String:AnyObject]{
                            tp.started = true
                            traverseDictionary(tp.value as! [String:AnyObject])
                        }
                        else{
                            tp.started = true
                            traverseArray(tp.value as! [[String:AnyObject]])
                        }
                    }
                }
            }
        }
        
        
    }
    
    private func traverseArray(JSON:[[String:AnyObject]]){
        for entry in JSON{
            traverseDictionary(entry)
        }
    }
    
    func writeLine(message:String)->String{
        numberOfLinesGenerated += 1
        return message + "\r\n"
    }
    
    func writeList(){
        var fileString = writeLine("")
        
        if singleFile{
            fileString += writeLine("import Foundation")
            fileString += writeLine("") //line break
        }
        for cls in classList{
            var clsName = cls.className.firstCapitalizedString
            if clsName.hasSuffix("s"){
                clsName = clsName.substringToIndex(clsName.endIndex.predecessor())
            }
            
            if NSClassFromString(clsName) != nil && ignoreImplementedClasses{
                print("\(clsName) exists")
            }else{
                if deliveryMethod == .FileSystem{
                    //TODO:print to local file system
                    if singleFile == false{
                        fileString = writeClass(cls)
                        _ = try? fileString.writeToFile(saveDirectory + "/" + clsName + ".swift",
                                                  atomically: true,
                                                  encoding: NSUTF8StringEncoding)
                    }
                    else{
                        fileString += writeClass(cls)
                    }
                }
                else{
                    fileString += writeClass(cls)
                    if !singleFile{
                        fileString += ("~eof~")
                    }
                }
            }
            if !singleFile && cls.className != classList.last!.className{
                fileString += writeLine("")
                fileString += writeLine("import Foundation")
                fileString += writeLine("") //line break
            }
        }
        if deliveryMethod == .URL{
            post(["code":fileString,"lines":numberOfLinesGenerated,"singleFile":singleFile], url: "http://www.jsonsuggest.com/api/uploadCode")
        }
        else if deliveryMethod == .FileSystem{
            if singleFile{
                _ = try? fileString.writeToFile(saveDirectory + "/Models.swift",
                                                atomically: true,
                                                encoding: NSUTF8StringEncoding)
            }
            print("Your files have been saved to : \(saveDirectory)")
            print("")
            if singleFile{
                print("Models.swift")
            }
            else{
                for cls in classList {
                    var clsName = cls.className.firstCapitalizedString
                    if clsName.hasSuffix("s"){
                        clsName = clsName.substringToIndex(clsName.endIndex.predecessor())
                    }
                    print("\(clsName).swift")
                }
            }
            print("")
            print("=== Stats ===")
            print("")
            print("Number of lines generated: \(numberOfLinesGenerated)")
            print("Total time saved: \(Float(numberOfLinesGenerated)/750.0 * 8)")
            print("(Assuming 750 lines of code per day is typical for this type of work)")
            print("")
            print("💰 If your time is valuable, please consider donating to futher development at the link below... 💰")
            print("")
            print("https://cash.me/$AndrewGene")
            print("")
            print("Thanks")
        }
        //print("*********************-End Suggestions-***********************")
    }
    
    func writeClass(cls:SuggestClass)->String{
        var fileString = ""
        var clsName = cls.className.firstCapitalizedString
        if clsName.hasSuffix("s"){
            clsName = clsName.substringToIndex(clsName.endIndex.predecessor())
        }
        if ignoreImplementedClasses{
            fileString += writeLine("@objc(\(clsName))")
        }
        fileString += writeLine("public class \(clsName)\(ignoreImplementedClasses ? " : NSObject" : ""){")
        fileString += writeLine("") //line break
        for prop in cls.properties{
            var propString = "    var \(prop.name.propertycaseString)\(prop.isOptional ? " : \(prop.type.firstCapitalizedString)?" : "") = "
            if prop.isOptional{
                propString += "nil"
                if prop.type == "UNDEFINED"{
                    propString = propString.stringByReplacingOccurrencesOfString("UNDEFINED", withString: "String")
                    propString += " //**This was actually undefined--being set to String by default**"
                }
            }
            else{
                if prop.type.hasPrefix("["){
                    propString += "\(prop.type.firstCapitalizedString)()"
                }
                else if defaultValues[prop.type.firstCapitalizedString] != nil{
                    propString += defaultValues[prop.type.firstCapitalizedString]!
                }
                else{
                    propString += prop.type.stringByReplacingOccurrencesOfString("UNDEFINED", withString: "\"\" //**This was actually undefined--being set to String by default**")
                }
            }
            
            fileString += writeLine(propString)
        }
        fileString += writeLine("") //line break
        for cl in cls.subClasses{
            var className = cl.className.firstCapitalizedString
            if className.hasSuffix("s"){
                className = className.substringToIndex(className.endIndex.predecessor())
            }
            if cl.isOptional{
                let clString = "    var \(cl.className.propertycaseString) : \(className)? = nil"
                fileString += writeLine(clString)
            }
            else{
                let clString = "    var \(cl.className.propertycaseString) = \(className)()"
                fileString += writeLine(clString)
            }
        }
        
        fileString += writeLine("") //line break
        fileString += writeLine("    \(ignoreImplementedClasses ? "override " : "")init(){")
        fileString += writeLine("") //line break
        fileString += writeLine("    }")
        
        fileString += writeLine("") //line break
        fileString += writeLine("    init?(JSON:AnyObject?){")
        fileString += writeLine("        var json = JSON")
        fileString += writeLine("        if json != nil{")
        fileString += writeLine("            if json is [String:AnyObject]{")
        fileString += writeLine("                if let firstKey = (json as! [String:AnyObject]).keys.first{")
        fileString += writeLine("                    if firstKey == \"\(clsName)\"{")
        fileString += writeLine("                        json = json![firstKey]")
        fileString += writeLine("                    }")
        fileString += writeLine("                }")
        fileString += writeLine("") //line break
        //meat of the class goes here
        let optionalProperties = cls.properties.filter({$0.isOptional})
        let requiredProperties = cls.properties.filter({!$0.isOptional})
        let optionalClasses = cls.subClasses.filter({!$0.isOptional})
        let requiredClasses = cls.subClasses.filter({!$0.isOptional})
        /*for property in cls.properties {
         if property.type.hasPrefix("[") && !property.isSimple(){
         //array of objects
         print("        if let \(property.name.propertycaseString) = json[\"\(property.name)\"] as? [[String:AnyObject]]{")
         print("            self.\(property.name.propertycaseString) = \(property.type.stringByReplacingOccurrencesOfString("[", withString: "").stringByReplacingOccurrencesOfString("]", withString: "")).fromJSONArray(\(property.name.propertycaseString))")
         print("        }")
         }
         /*else if !property.isSimple(){
         //object
         print("        if let \(property.name.propertycaseString) = json[\"\(property.name)\"] as? [String:AnyObject]{")
         print("            self.\(property.name.propertycaseString) = \(property.type)(\(property.name.propertycaseString))")
         print("        }")
         }*/
         else{
         print("        if let \(property.name.propertycaseString) = json[\"\(property.name)\"] as? \(property.type.firstCapitalizedString.stringByReplacingOccurrencesOfString("UNDEFINED", withString: "String")){")
         print("            self.\(property.name.propertycaseString) = \(property.name.propertycaseString)")
         print("        }")
         }
         }*/
        if requiredProperties.count > 0{
            fileString += writeLine("                guard")
            for property in requiredProperties{
                if property.type.hasPrefix("[") && !property.isSimple(){
                    //array of objects
                    fileString += writeLine("                    let \(property.name.propertycaseString) = json?[\"\(property.name)\"] as? [[String:AnyObject]]\(property.name == requiredProperties.last!.name ? "" : ",")")
                    //print("            self.\(property.name.propertycaseString) = \(property.type.stringByReplacingOccurrencesOfString("[", withString: "").stringByReplacingOccurrencesOfString("]", withString: "")).fromJSONArray(\(property.name.propertycaseString))")
                    //print("        }")
                }
                else{
                    fileString += writeLine("                    let \(property.name.propertycaseString) = json?[\"\(property.name)\"] as? \(property.type.firstCapitalizedString.stringByReplacingOccurrencesOfString("UNDEFINED", withString: "String"))\(property.name == requiredProperties.last!.name ? "" : ",")")
                    //print("            self.\(property.name.propertycaseString) = \(property.name.propertycaseString)")
                    //print("        }")
                }
            }
            fileString += writeLine("                else{")
            //print("                    print(\"required \(clsName) property is missing\")")
            fileString += writeLine("                    return nil")
            fileString += writeLine("                }")
            fileString += writeLine("") //line break
            for property in requiredProperties{
                if property.type.hasPrefix("[") && !property.isSimple(){
                    fileString += writeLine("                self.\(property.name.propertycaseString) = \(property.type.stringByReplacingOccurrencesOfString("[", withString: "").stringByReplacingOccurrencesOfString("]", withString: "")).fromJSONArray(\(property.name.propertycaseString))")
                }
                else{
                    fileString += writeLine("                self.\(property.name.propertycaseString) = \(property.name.propertycaseString)")
                }
            }
            fileString += writeLine("") //line break
        }
        for property in optionalProperties {
            if property.type.hasPrefix("[") && !property.isSimple(){
                //array of objects
                fileString += writeLine("                if let \(property.name.propertycaseString) = json?[\"\(property.name)\"] as? [[String:AnyObject]]{")
                fileString += writeLine("                    self.\(property.name.propertycaseString) = \(property.type.stringByReplacingOccurrencesOfString("[", withString: "").stringByReplacingOccurrencesOfString("]", withString: "")).fromJSONArray(\(property.name.propertycaseString))")
                fileString += writeLine("                }")
            }
                /*else if !property.isSimple(){
                 //object
                 print("        if let \(property.name.propertycaseString) = json[\"\(property.name)\"] as? [String:AnyObject]{")
                 print("            self.\(property.name.propertycaseString) = \(property.type)(\(property.name.propertycaseString))")
                 print("        }")
                 }*/
            else{
                fileString += writeLine("                if let \(property.name.propertycaseString) = json?[\"\(property.name)\"] as? \(property.type.firstCapitalizedString.stringByReplacingOccurrencesOfString("UNDEFINED", withString: "String")){")
                fileString += writeLine("                    self.\(property.name.propertycaseString) = \(property.name.propertycaseString)")
                fileString += writeLine("                }")
            }
        }
        if optionalProperties.count > 0{
            fileString += writeLine("") //line break
        }
        if requiredClasses.count > 0{
            fileString += writeLine("                guard")
            for sub in requiredClasses{
                var className = sub.className.firstCapitalizedString
                if className.hasSuffix("s"){
                    className = className.substringToIndex(className.endIndex.predecessor())
                }
                fileString += writeLine("                    let \(sub.className.propertycaseString) = json?[\"\(sub.className)\"] as? [[String:AnyObject]]\(sub.className == requiredClasses.last!.className ? "" : ",")")
            }
            fileString += writeLine("                else{")
            //print("                    print(\"required \(clsName) class is missing\")")
            fileString += writeLine("                    return nil")
            fileString += writeLine("                }")
            fileString += writeLine("") //line break
            for sub in requiredClasses{
                fileString += writeLine("                self.\(sub.className.propertycaseString) = \(sub.className.propertycaseString)")
            }
            fileString += writeLine("") //line break
        }
        for sub in optionalClasses{
            var className = sub.className.firstCapitalizedString
            if className.hasSuffix("s"){
                className = className.substringToIndex(className.endIndex.predecessor())
            }
            fileString += writeLine("                if let \(sub.className.propertycaseString) = json?[\"\(sub.className)\"] as? [String:AnyObject]{")
            fileString += writeLine("                    self.\(sub.className.propertycaseString) = \(className)(JSON: \(sub.className.propertycaseString))")
            fileString += writeLine("                }")
        }
        if optionalClasses.count > 0{
            fileString += writeLine("") //line break
        }
        /*for sub in cls.subClasses{
         var className = sub.className.firstCapitalizedString
         if className.hasSuffix("s"){
         className = className.substringToIndex(className.endIndex.predecessor())
         }
         print("                if let \(sub.className.propertycaseString) = json?[\"\(sub.className)\"] as? [String:AnyObject]{")
         print("                    self.\(sub.className.propertycaseString) = \(className)(JSON: \(sub.className.propertycaseString))")
         print("                }")
         }*/
        //end of meat
        fileString += writeLine("") //line break
        fileString += writeLine("            }")
        fileString += writeLine("            else{")
        fileString += writeLine("                return nil")
        fileString += writeLine("            }")
        fileString += writeLine("        }")
        fileString += writeLine("        else{")
        fileString += writeLine("            return nil")
        fileString += writeLine("        }")
        fileString += writeLine("    }")
        
        fileString += writeLine("") //line break
        fileString += writeLine("    class func fromJSONArray(JSON:[[String:AnyObject]]) -> [\(clsName)]{")
        fileString += writeLine("        var returnArray = [\(clsName)]()")
        fileString += writeLine("        for entry in JSON{")
        fileString += writeLine("            if let ent = \(clsName)(JSON: entry){")
        fileString += writeLine("                returnArray.append(ent)")
        fileString += writeLine("            }")
        fileString += writeLine("        }")
        fileString += writeLine("        return returnArray")
        fileString += writeLine("    }")
        fileString += writeLine("") //line break
        fileString += writeLine("    private func traverseJSON(inout \(clsName.propertycaseString + "s"):[\(clsName)], JSON:AnyObject, complete:((\(clsName.propertycaseString + "s"):[\(clsName)])->())?){")
        fileString += writeLine("        if JSON is [String:AnyObject]{")
        fileString += writeLine("            for (_,v) in (JSON as! [String:AnyObject]){")
        fileString += writeLine("                if v is [String:AnyObject]{")
        fileString += writeLine("                    if let attempt = \(clsName)(JSON: v as! [String:AnyObject]){")
        fileString += writeLine("                        \(clsName.propertycaseString + "s").append(attempt)")
        fileString += writeLine("                    }")
        fileString += writeLine("                    traverseJSON(&\(clsName.propertycaseString + "s"), JSON: v as! [String:AnyObject], complete: nil)")
        fileString += writeLine("                }")
        fileString += writeLine("                else if v is [[String:AnyObject]]{")
        fileString += writeLine("                    traverseJSON(&\(clsName.propertycaseString + "s"), JSON: v as! [[String:AnyObject]], complete: nil)")
        fileString += writeLine("                }")
        fileString += writeLine("            }")
        fileString += writeLine("        }")
        fileString += writeLine("        else if JSON is [[String:AnyObject]]{")
        fileString += writeLine("            for entry in (JSON as! [[String:AnyObject]]){")
        fileString += writeLine("                if let attempt = \(clsName)(JSON: entry){")
        fileString += writeLine("                    \(clsName.propertycaseString + "s").append(attempt)")
        fileString += writeLine("                }")
        fileString += writeLine("                else{")
        fileString += writeLine("                    traverseJSON(&\(clsName.propertycaseString + "s"), JSON: entry, complete: nil)")
        fileString += writeLine("                }")
        fileString += writeLine("            }")
        fileString += writeLine("        }")
        fileString += writeLine("        if complete != nil{")
        fileString += writeLine("            complete!(\(clsName.propertycaseString + "s"): \(clsName.propertycaseString + "s"))")
        fileString += writeLine("        }")
        fileString += writeLine("    }")
        fileString += writeLine("") //line break
        fileString += writeLine("    func findInJSON(JSON:AnyObject, complete:((\(clsName.propertycaseString + "s"):[\(clsName)])->())?){")
        fileString += writeLine("        var \(clsName.propertycaseString + "s") = [\(clsName)]()")
        fileString += writeLine("        traverseJSON(&\(clsName.propertycaseString + "s"), JSON: JSON) { (\(clsName.propertycaseString + "s")) in")
        fileString += writeLine("            if complete != nil{")
        fileString += writeLine("                complete!(\(clsName.propertycaseString + "s"): \(clsName.propertycaseString + "s"))")
        fileString += writeLine("            }")
        fileString += writeLine("        }")
        fileString += writeLine("    }")
        fileString += writeLine("") //line break
        fileString += writeLine("}")
        
        fileString += writeLine("") //line break
        fileString += writeLine("extension \(clsName){")
        fileString += writeLine("    var toJSON: [String:AnyObject] {")
        fileString += writeLine("        var jsonObject = [String:AnyObject]()")
        for property in requiredProperties{
            if property.isSimple() || property.type == "UNDEFINED"{
                fileString += writeLine("        jsonObject[\"\(property.name.propertycaseString)\"] = self.\(property.name.propertycaseString)")
            }
            else{
                fileString += writeLine("        jsonObject[\"\(property.name.propertycaseString)\"] = self.\(property.name.propertycaseString).toJSONArray")
            }
        }
        if requiredProperties.count > 0{
            fileString += writeLine("") //line break
        }
        for property in optionalProperties{
            if property.isSimple() || property.type == "UNDEFINED"{
                fileString += writeLine("        if self.\(property.name.propertycaseString) != nil{")
                fileString += writeLine("            jsonObject[\"\(property.name.propertycaseString)\"] = self.\(property.name.propertycaseString)!")
                fileString += writeLine("        }")
            }
            else{
                fileString += writeLine("        if self.\(property.name.propertycaseString) != nil{")
                fileString += writeLine("            jsonObject[\"\(property.name.propertycaseString)\"] = self.\(property.name.propertycaseString)!.toJSONArray")
                fileString += writeLine("        }")
            }
        }
        if optionalProperties.count > 0{
            fileString += writeLine("") //line break
        }
        for sub in requiredClasses{
            fileString += writeLine("        jsonObject[\"\(sub.className.propertycaseString)\"] = self.\(sub.className.propertycaseString).toJSON")
        }
        if requiredClasses.count > 0{
            fileString += writeLine("") //line break
        }
        for sub in optionalClasses{
            fileString += writeLine("        if self.\(sub.className.propertycaseString) != nil{")
            fileString += writeLine("        jsonObject[\"\(sub.className.propertycaseString)\"] = self.\(sub.className.propertycaseString).toJSON")
            fileString += writeLine("        }")
        }
        if optionalClasses.count > 0{
            fileString += writeLine("") //line break
        }
        fileString += writeLine("        return jsonObject")
        fileString += writeLine("    }")
        fileString += writeLine("") //line break
        fileString += writeLine("    var toJSONString: String {")
        fileString += writeLine("        var jsonString = \"\"")
        for property in requiredProperties{
            if property.isSimple() || property.type == "UNDEFINED"{
                fileString += writeLine("        jsonString += \", \\\"\(property.name.propertycaseString)\\\":\\\"\\(self.\(property.name.propertycaseString))\\\"\"")
            }
            else{
                fileString += writeLine("        jsonString += \", \\\"\(property.name.propertycaseString)\\\":\\\"\\(self.\(property.name.propertycaseString).toJSONString)\\\"\"")
            }
        }
        if requiredProperties.count > 0{
            fileString += writeLine("") //line break
        }
        for property in optionalProperties{
            if property.isSimple() || property.type == "UNDEFINED"{
                fileString += writeLine("        if self.\(property.name.propertycaseString) != nil{")
                fileString += writeLine("            jsonString += \", \\\"\(property.name.propertycaseString)\\\":\\\"\\(self.\(property.name.propertycaseString)!)\\\"\"")
                fileString += writeLine("        }")
            }
            else{
                fileString += writeLine("        if self.\(property.name.propertycaseString) != nil{")
                fileString += writeLine("            jsonString += \", \\\"\(property.name.propertycaseString)\\\":\\\"\\(self.\(property.name.propertycaseString)!.toJSONString)\\\"\"")
                fileString += writeLine("        }")
            }
        }
        if optionalProperties.count > 0{
            fileString += writeLine("") //line break
        }
        for sub in requiredClasses{
            fileString += writeLine("        jsonString += \", \\\"\(sub.className.propertycaseString)\\\":\\\"\\(self.\(sub.className.propertycaseString).toJSONString)\\\"\"")
        }
        if requiredClasses.count > 0{
            fileString += writeLine("") //line break
        }
        for sub in optionalClasses{
            fileString += writeLine("        if self.\(sub.className.propertycaseString) != nil{")
            fileString += writeLine("            jsonString += \", \\\"\(sub.className.propertycaseString)\\\":\\\"\\(self.\(sub.className.propertycaseString).toJSONString)\\\"\"")
            fileString += writeLine("        }")
        }
        if optionalClasses.count > 0{
            fileString += writeLine("") //line break
        }
        if cls.properties.count + cls.subClasses.count > 0{
            fileString += writeLine("        jsonString = String(jsonString.characters.dropFirst()) //removes the ','")
            fileString += writeLine("        jsonString = String(jsonString.characters.dropFirst()) //removes the beginning space")
        }
        fileString += writeLine("") //line break
        fileString += writeLine("        return jsonString")
        fileString += writeLine("    }")
        
        fileString += writeLine("}")
        
        fileString += writeLine("") //line break
        fileString += writeLine("extension Array where Element:\(clsName){")
        fileString += writeLine("    var toJSONArray : [[String:AnyObject]]{")
        fileString += writeLine("        var returnArray = [[String:AnyObject]]()")
        fileString += writeLine("        for entry in self{")
        fileString += writeLine("            returnArray.append(entry.toJSON)")
        fileString += writeLine("        }")
        fileString += writeLine("        return returnArray")
        fileString += writeLine("    }")
        fileString += writeLine("") //line break
        fileString += writeLine("    var toJSONString : String{")
        fileString += writeLine("        var returnString = \"\"")
        fileString += writeLine("        for entry in self{")
        fileString += writeLine("            returnString += entry.toJSONString")
        fileString += writeLine("        }")
        fileString += writeLine("        return returnString")
        fileString += writeLine("    }")
        fileString += writeLine("}")
        
        fileString += writeLine("") //line break
        
        return fileString
    }

    func printList(){
        
        if ignoreImplementedClasses{
            print("!!!!! FOR THE \"ignoreImplementedClasses\" FEATURE TO WORK, THE CLASS MUST SUBCLASS NSOBJECT !!!!!")
        }
        
        //print("********************-Class Suggestions-************************")
        print("") //line break
        if singleFile{
            print("import Foundation")
            print("") //line break
        }
        for cls in classList{
            var clsName = cls.className.firstCapitalizedString
            if clsName.hasSuffix("s"){
                clsName = clsName.substringToIndex(clsName.endIndex.predecessor())
            }
            
            if NSClassFromString(clsName) != nil && ignoreImplementedClasses{
                print("\(clsName) exists")
            }else{
                printClass(cls)
                if !singleFile{
                    print("~eof~")
                }
            }
            if !singleFile && cls.className != classList.last!.className{
                print("")
                print("import Foundation")
                print("") //line break
            }
            
           
        }
        //print("*********************-End Suggestions-***********************")
    }
    
    func printClass(cls:SuggestClass){
        var clsName = cls.className.firstCapitalizedString
        if clsName.hasSuffix("s"){
            clsName = clsName.substringToIndex(clsName.endIndex.predecessor())
        }
        if ignoreImplementedClasses{
            print("@objc(\(clsName))")
        }
        print("public class \(clsName)\(ignoreImplementedClasses ? " : NSObject" : ""){")
        print("") //line break
        for prop in cls.properties{
            var propString = "    var \(prop.name.propertycaseString)\(prop.isOptional ? " : \(prop.type.firstCapitalizedString)?" : "") = "
            if prop.isOptional{
                propString += "nil"
                if prop.type == "UNDEFINED"{
                    propString = propString.stringByReplacingOccurrencesOfString("UNDEFINED", withString: "String")
                    propString += " //**This was actually undefined--being set to String by default**"
                }
            }
            else{
                if prop.type.hasPrefix("["){
                    propString += "\(prop.type.firstCapitalizedString)()"
                }
                else if defaultValues[prop.type.firstCapitalizedString] != nil{
                    propString += defaultValues[prop.type.firstCapitalizedString]!
                }
                else{
                    propString += prop.type.stringByReplacingOccurrencesOfString("UNDEFINED", withString: "\"\" //**This was actually undefined--being set to String by default**")
                }
            }
            
            print(propString)
        }
        print("") //line break
        for cl in cls.subClasses{
            var className = cl.className.firstCapitalizedString
            if className.hasSuffix("s"){
                className = className.substringToIndex(className.endIndex.predecessor())
            }
            if cl.isOptional{
                let clString = "    var \(cl.className.propertycaseString) : \(className)? = nil"
                print(clString)
            }
            else{
                let clString = "    var \(cl.className.propertycaseString) = \(className)()"
                print(clString)
            }
        }
        
        print("") //line break
        print("    \(ignoreImplementedClasses ? "override " : "")init(){")
        print("") //line break
        print("    }")
        
        print("") //line break
        print("    init?(JSON:AnyObject?){")
        print("        var json = JSON")
        print("        if json != nil{")
        print("            if json is [String:AnyObject]{")
        print("                if let firstKey = (json as! [String:AnyObject]).keys.first{")
        print("                    if firstKey == \"\(clsName)\"{")
        print("                        json = json![firstKey]")
        print("                    }")
        print("                }")
        print("") //line break
        //meat of the class goes here
        let optionalProperties = cls.properties.filter({$0.isOptional})
        let requiredProperties = cls.properties.filter({!$0.isOptional})
        let optionalClasses = cls.subClasses.filter({!$0.isOptional})
        let requiredClasses = cls.subClasses.filter({!$0.isOptional})
        /*for property in cls.properties {
         if property.type.hasPrefix("[") && !property.isSimple(){
         //array of objects
         print("        if let \(property.name.propertycaseString) = json[\"\(property.name)\"] as? [[String:AnyObject]]{")
         print("            self.\(property.name.propertycaseString) = \(property.type.stringByReplacingOccurrencesOfString("[", withString: "").stringByReplacingOccurrencesOfString("]", withString: "")).fromJSONArray(\(property.name.propertycaseString))")
         print("        }")
         }
         /*else if !property.isSimple(){
         //object
         print("        if let \(property.name.propertycaseString) = json[\"\(property.name)\"] as? [String:AnyObject]{")
         print("            self.\(property.name.propertycaseString) = \(property.type)(\(property.name.propertycaseString))")
         print("        }")
         }*/
         else{
         print("        if let \(property.name.propertycaseString) = json[\"\(property.name)\"] as? \(property.type.firstCapitalizedString.stringByReplacingOccurrencesOfString("UNDEFINED", withString: "String")){")
         print("            self.\(property.name.propertycaseString) = \(property.name.propertycaseString)")
         print("        }")
         }
         }*/
        if requiredProperties.count > 0{
            print("                guard")
            for property in requiredProperties{
                if property.type.hasPrefix("[") && !property.isSimple(){
                    //array of objects
                    print("                    let \(property.name.propertycaseString) = json?[\"\(property.name)\"] as? [[String:AnyObject]]\(property.name == requiredProperties.last!.name ? "" : ",")")
                    //print("            self.\(property.name.propertycaseString) = \(property.type.stringByReplacingOccurrencesOfString("[", withString: "").stringByReplacingOccurrencesOfString("]", withString: "")).fromJSONArray(\(property.name.propertycaseString))")
                    //print("        }")
                }
                else{
                    print("                    let \(property.name.propertycaseString) = json?[\"\(property.name)\"] as? \(property.type.firstCapitalizedString.stringByReplacingOccurrencesOfString("UNDEFINED", withString: "String"))\(property.name == requiredProperties.last!.name ? "" : ",")")
                    //print("            self.\(property.name.propertycaseString) = \(property.name.propertycaseString)")
                    //print("        }")
                }
            }
            print("                else{")
            //print("                    print(\"required \(clsName) property is missing\")")
            print("                    return nil")
            print("                }")
            print("") //line break
            for property in requiredProperties{
                if property.type.hasPrefix("[") && !property.isSimple(){
                    print("                self.\(property.name.propertycaseString) = \(property.type.stringByReplacingOccurrencesOfString("[", withString: "").stringByReplacingOccurrencesOfString("]", withString: "")).fromJSONArray(\(property.name.propertycaseString))")
                }
                else{
                    print("                self.\(property.name.propertycaseString) = \(property.name.propertycaseString)")
                }
            }
            print("") //line break
        }
        for property in optionalProperties {
            if property.type.hasPrefix("[") && !property.isSimple(){
                //array of objects
                print("                if let \(property.name.propertycaseString) = json?[\"\(property.name)\"] as? [[String:AnyObject]]{")
                print("                    self.\(property.name.propertycaseString) = \(property.type.stringByReplacingOccurrencesOfString("[", withString: "").stringByReplacingOccurrencesOfString("]", withString: "")).fromJSONArray(\(property.name.propertycaseString))")
                print("                }")
            }
                /*else if !property.isSimple(){
                 //object
                 print("        if let \(property.name.propertycaseString) = json[\"\(property.name)\"] as? [String:AnyObject]{")
                 print("            self.\(property.name.propertycaseString) = \(property.type)(\(property.name.propertycaseString))")
                 print("        }")
                 }*/
            else{
                print("                if let \(property.name.propertycaseString) = json?[\"\(property.name)\"] as? \(property.type.firstCapitalizedString.stringByReplacingOccurrencesOfString("UNDEFINED", withString: "String")){")
                print("                    self.\(property.name.propertycaseString) = \(property.name.propertycaseString)")
                print("                }")
            }
        }
        if optionalProperties.count > 0{
            print("") //line break
        }
        if requiredClasses.count > 0{
            print("                guard")
            for sub in requiredClasses{
                var className = sub.className.firstCapitalizedString
                if className.hasSuffix("s"){
                    className = className.substringToIndex(className.endIndex.predecessor())
                }
                print("                    let \(sub.className.propertycaseString) = json?[\"\(sub.className)\"] as? [[String:AnyObject]]\(sub.className == requiredClasses.last!.className ? "" : ",")")
            }
            print("                else{")
            //print("                    print(\"required \(clsName) class is missing\")")
            print("                    return nil")
            print("                }")
            print("") //line break
            for sub in requiredClasses{
                print("                self.\(sub.className.propertycaseString) = \(sub.className.propertycaseString)")
            }
            print("") //line break
        }
        for sub in optionalClasses{
            var className = sub.className.firstCapitalizedString
            if className.hasSuffix("s"){
                className = className.substringToIndex(className.endIndex.predecessor())
            }
            print("                if let \(sub.className.propertycaseString) = json?[\"\(sub.className)\"] as? [String:AnyObject]{")
            print("                    self.\(sub.className.propertycaseString) = \(className)(JSON: \(sub.className.propertycaseString))")
            print("                }")
        }
        if optionalClasses.count > 0{
            print("") //line break
        }
        /*for sub in cls.subClasses{
            var className = sub.className.firstCapitalizedString
            if className.hasSuffix("s"){
                className = className.substringToIndex(className.endIndex.predecessor())
            }
            print("                if let \(sub.className.propertycaseString) = json?[\"\(sub.className)\"] as? [String:AnyObject]{")
            print("                    self.\(sub.className.propertycaseString) = \(className)(JSON: \(sub.className.propertycaseString))")
            print("                }")
        }*/
        //end of meat
        print("") //line break
        print("            }")
        print("            else{")
        print("                return nil")
        print("            }")
        print("        }")
        print("        else{")
        print("            return nil")
        print("        }")
        print("    }")
        
        print("") //line break
        print("    class func fromJSONArray(JSON:[[String:AnyObject]]) -> [\(clsName)]{")
        print("        var returnArray = [\(clsName)]()")
        print("        for entry in JSON{")
        print("            if let ent = \(clsName)(JSON: entry){")
        print("                returnArray.append(ent)")
        print("            }")
        print("        }")
        print("        return returnArray")
        print("    }")
        print("") //line break
        print("    private func traverseJSON(inout \(clsName.propertycaseString + "s"):[\(clsName)], JSON:AnyObject, complete:((\(clsName.propertycaseString + "s"):[\(clsName)])->())?){")
        print("        if JSON is [String:AnyObject]{")
        print("            for (_,v) in (JSON as! [String:AnyObject]){")
        print("                if v is [String:AnyObject]{")
        print("                    if let attempt = \(clsName)(JSON: v as! [String:AnyObject]){")
        print("                        \(clsName.propertycaseString + "s").append(attempt)")
        print("                    }")
        print("                    traverseJSON(&\(clsName.propertycaseString + "s"), JSON: v as! [String:AnyObject], complete: nil)")
        print("                }")
        print("                else if v is [[String:AnyObject]]{")
        print("                    traverseJSON(&\(clsName.propertycaseString + "s"), JSON: v as! [[String:AnyObject]], complete: nil)")
        print("                }")
        print("            }")
        print("        }")
        print("        else if JSON is [[String:AnyObject]]{")
        print("            for entry in (JSON as! [[String:AnyObject]]){")
        print("                if let attempt = \(clsName)(JSON: entry){")
        print("                    \(clsName.propertycaseString + "s").append(attempt)")
        print("                }")
        print("                else{")
        print("                    traverseJSON(&\(clsName.propertycaseString + "s"), JSON: entry, complete: nil)")
        print("                }")
        print("            }")
        print("        }")
        print("        if complete != nil{")
        print("            complete!(\(clsName.propertycaseString + "s"): \(clsName.propertycaseString + "s"))")
        print("        }")
        print("    }")
        print("") //line break
        print("    func findInJSON(JSON:AnyObject, complete:((\(clsName.propertycaseString + "s"):[\(clsName)])->())?){")
        print("        var \(clsName.propertycaseString + "s") = [\(clsName)]()")
        print("        traverseJSON(&\(clsName.propertycaseString + "s"), JSON: JSON) { (\(clsName.propertycaseString + "s")) in")
        print("            if complete != nil{")
        print("                complete!(\(clsName.propertycaseString + "s"): \(clsName.propertycaseString + "s"))")
        print("            }")
        print("        }")
        print("    }")
        print("") //line break
        print("}")
        
        print("") //line break
        print("extension \(clsName){")
        print("    var toJSON: [String:AnyObject] {")
        print("        var jsonObject = [String:AnyObject]()")
        for property in requiredProperties{
            if property.isSimple() || property.type == "UNDEFINED"{
                print("        jsonObject[\"\(property.name.propertycaseString)\"] = self.\(property.name.propertycaseString)")
            }
            else{
                print("        jsonObject[\"\(property.name.propertycaseString)\"] = self.\(property.name.propertycaseString).toJSONArray")
            }
        }
        if requiredProperties.count > 0{
            print("") //line break
        }
        for property in optionalProperties{
            if property.isSimple() || property.type == "UNDEFINED"{
                print("        if self.\(property.name.propertycaseString) != nil{")
                print("            jsonObject[\"\(property.name.propertycaseString)\"] = self.\(property.name.propertycaseString)!")
                print("        }")
            }
            else{
                print("        if self.\(property.name.propertycaseString) != nil{")
                print("            jsonObject[\"\(property.name.propertycaseString)\"] = self.\(property.name.propertycaseString)!.toJSONArray")
                print("        }")
            }
        }
        if optionalProperties.count > 0{
            print("") //line break
        }
        for sub in requiredClasses{
            print("        jsonObject[\"\(sub.className.propertycaseString)\"] = self.\(sub.className.propertycaseString).toJSON")
        }
        if requiredClasses.count > 0{
            print("") //line break
        }
        for sub in optionalClasses{
            print("        if self.\(sub.className.propertycaseString) != nil{")
            print("        jsonObject[\"\(sub.className.propertycaseString)\"] = self.\(sub.className.propertycaseString).toJSON")
            print("        }")
        }
        if optionalClasses.count > 0{
            print("") //line break
        }
        print("        return jsonObject")
        print("    }")
        print("") //line break
        print("    var toJSONString: String {")
        print("        var jsonString = \"\"")
        for property in requiredProperties{
            if property.isSimple() || property.type == "UNDEFINED"{
                print("        jsonString += \", \\\"\(property.name.propertycaseString)\\\":\\\"\\(self.\(property.name.propertycaseString))\\\"\"")
            }
            else{
                print("        jsonString += \", \\\"\(property.name.propertycaseString)\\\":\\\"\\(self.\(property.name.propertycaseString).toJSONString)\\\"\"")
            }
        }
        if requiredProperties.count > 0{
            print("") //line break
        }
        for property in optionalProperties{
            if property.isSimple() || property.type == "UNDEFINED"{
                print("        if self.\(property.name.propertycaseString) != nil{")
                print("            jsonString += \", \\\"\(property.name.propertycaseString)\\\":\\\"\\(self.\(property.name.propertycaseString)!)\\\"\"")
                print("        }")
            }
            else{
                print("        if self.\(property.name.propertycaseString) != nil{")
                print("            jsonString += \", \\\"\(property.name.propertycaseString)\\\":\\\"\\(self.\(property.name.propertycaseString)!.toJSONString)\\\"\"")
                print("        }")
            }
        }
        if optionalProperties.count > 0{
            print("") //line break
        }
        for sub in requiredClasses{
            print("        jsonString += \", \\\"\(sub.className.propertycaseString)\\\":\\\"\\(self.\(sub.className.propertycaseString).toJSONString)\\\"\"")
        }
        if requiredClasses.count > 0{
            print("") //line break
        }
        for sub in optionalClasses{
            print("        if self.\(sub.className.propertycaseString) != nil{")
            print("            jsonString += \", \\\"\(sub.className.propertycaseString)\\\":\\\"\\(self.\(sub.className.propertycaseString).toJSONString)\\\"\"")
            print("        }")
        }
        if optionalClasses.count > 0{
            print("") //line break
        }
        if cls.properties.count + cls.subClasses.count > 0{
            print("        jsonString = String(jsonString.characters.dropFirst()) //removes the ','")
            print("        jsonString = String(jsonString.characters.dropFirst()) //removes the beginning space")
        }
        print("") //line break
        print("        return jsonString")
        print("    }")
        
        print("}")
        
        print("") //line break
        print("extension Array where Element:\(clsName){")
        print("    var toJSONArray : [[String:AnyObject]]{")
        print("        var returnArray = [[String:AnyObject]]()")
        print("        for entry in self{")
        print("            returnArray.append(entry.toJSON)")
        print("        }")
        print("        return returnArray")
        print("    }")
        print("") //line break
        print("    var toJSONString : String{")
        print("        var returnString = \"\"")
        print("        for entry in self{")
        print("            returnString += entry.toJSONString")
        print("        }")
        print("        return returnString")
        print("    }")
        print("}")
        
        print("") //line break
        
 
        //print("---------------------------")
        print("") //line break
    }
    
    func post(params : Dictionary<String, AnyObject>, url : String) {
        do {
            
            let jsonData = try NSJSONSerialization.dataWithJSONObject(params, options: .PrettyPrinted)
            
            // create post request
            let url = NSURL(string: url)!
            let request = NSMutableURLRequest(URL: url)
            request.HTTPMethod = "POST"
            
            // insert json data to the request
            request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
            request.HTTPBody = jsonData
            
            
            let task = NSURLSession.sharedSession().dataTaskWithRequest(request){ data, response, error in
                if error != nil{
                    print("Error -> \(error)")
                    return
                }
                
                do {
                    if let result = try NSJSONSerialization.JSONObjectWithData(data!, options: []) as? [String:AnyObject]{
                        if let link = result["link"] as? String{
                            print("Download your file at ... ****************************************")
                            print("")
                            print("  👉  \(link)  👈 ")
                            print("")
                            print("This link is only good for 1 hour")
                            print("")
                            print("‼️ NO VALUES FROM AN API ARE EVER SENT TO jsonsuggest.com ‼️")
                            print("******************************************************************")
                        }
                    }
                    
                } catch {
                    print("Error -> \(error)")
                }
            }
            
            task.resume()
            
        } catch {
            print(error)
        }
    }
}

public enum DeliveryMethod: String{
    case Console = "Console"
    case URL = "URL"
    case FileSystem = "FileSystem"
}

public class SuggestClass{
    var className = ""
    var subClasses = [SuggestClass]()
    var properties = [SuggestProperty]()
    var isFromArray = false
    var maxIterations = 1
    var iterations = 0
    var toParse = [SuggestToParse]()
    var instances = 0
    var isOptional = false
    init(className:String){
        self.className = className
    }
    
    func hasClass(name:String)->Bool{
        return self.subClasses.filter({$0.className == name}).count > 0
    }
    
    func hasProperty(name:String)->Bool{
        return self.properties.filter({$0.name == name}).count > 0
    }
}

public class SuggestProperty{
    var type = ""
    var isOptional = false
    var name = ""
    var canBeReplaced = true //some JSON messages will use "" for a null value; when this is the case, we map it to a String value but might replace it with another type once it is filled in
    var instances = 1
    
    func isSimple()->Bool{
        if type == "String" || type == "Int" || type == "Double" || type == "Float" || type == "Bool" || type == "[String]" || type == "[Int]" || type == "[Double]" || type == "[Float]" || type == "[Bool]"{
            return true
        }
        return false
    }
}

public class SuggestToParse{
    var key = ""
    var value:AnyObject? = nil
    var started = false
}

extension String{
    var propertycaseString: String {
        let source = self
        if source == source.uppercaseString{
            return source
        }
        var multipleUpperCaseInARow = false
        var lastCharUpperCase = false
        var upperCaseInFront = false
        var i = 0
        for ch in source.characters{
            let char = "\(ch)"
            if char == char.uppercaseString{
                if lastCharUpperCase == true{
                    multipleUpperCaseInARow = true
                    if i == 1{
                        upperCaseInFront = true
                    }
                    break
                }
                lastCharUpperCase = true
            }
            else{
                lastCharUpperCase = false
            }
            i = i + 1
        }
        
        if multipleUpperCaseInARow{
            if !upperCaseInFront{
                return source.firstLowerCaseString
            }
            return source
        }
        else{
            return source.camelcaseString
        }
    }
    
    var camelcaseString: String {
        let source = self
        if source.characters.contains(" ") {
            let first = source.substringToIndex(source.startIndex.advancedBy(1))
            let cammel = source.capitalizedString.stringByReplacingOccurrencesOfString(" ", withString: "")
            let rest = String(cammel.characters.dropFirst())
            return "\(first)\(rest)"
        } else {
            let first = source.lowercaseString.substringToIndex(source.startIndex.advancedBy(1))
            let rest = String(source.characters.dropFirst())
            return "\(first)\(rest)"
        }
    }
    
    var firstCapitalizedString: String {
        let source = self
        var isArray = false
        if source.hasPrefix("["){
            isArray = true
        }
        let first:String
        let rest:String
        if isArray{
            let bufferString = String(source.characters.dropFirst())
            first = bufferString.lowercaseString.substringToIndex(bufferString.startIndex.advancedBy(1)).capitalizedString
            rest = String(bufferString.characters.dropFirst())
        }
        else{
            first = source.lowercaseString.substringToIndex(source.startIndex.advancedBy(1)).capitalizedString
            rest = String(source.characters.dropFirst())
        }
        
        return "\(isArray ? "[" : "")\(first)\(rest)"
    }
    
    var firstLowerCaseString: String {
        let source = self
        var isArray = false
        if source.hasPrefix("["){
            isArray = true
        }
        let first:String
        let rest:String
        if isArray{
            let bufferString = String(source.characters.dropFirst())
            first = bufferString.lowercaseString.substringToIndex(bufferString.startIndex.advancedBy(1)).lowercaseString
            rest = String(bufferString.characters.dropFirst())
        }
        else{
            first = source.lowercaseString.substringToIndex(source.startIndex.advancedBy(1)).lowercaseString
            rest = String(source.characters.dropFirst())
        }
        
        return "\(isArray ? "[" : "")\(first)\(rest)"
    }
}