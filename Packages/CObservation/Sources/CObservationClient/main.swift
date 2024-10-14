import CObservation
import Observation

//let a = 17
//let b = 25

//let (result, code) = #stringify(a + b)

//print("The value \(result) was produced by the code \"\(code)\"")


@CObservable
class MyClass {
    var aValue:Int = 2
    
    var _context:CObjectContext? { nil }
    
    func access() {
        print("This is the original access method running...")
    }
}

//
let myClass = MyClass()
//myClass.access()

myClass.aValue = 4
myClass.aValue = 102
