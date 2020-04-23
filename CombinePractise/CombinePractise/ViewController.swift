//
//  ViewController.swift
//  CombinePractise
//
//  Created by Anuj Rai on 09/04/20.
//  Copyright © 2020 Anuj Rai. All rights reserved.
//

import UIKit
import Combine

class ViewController: UIViewController {
    @IBOutlet weak var labelAssignSubscriber: UILabel!
    @IBOutlet weak var tapButton: UIButton!
    var buttonTapCount: Int = 0
    var cancellable: AnyCancellable?
    
    
    @Published var labelAssignSubscriberValueString: String? = "You dont tap the button" ///( Property wrapper can not be let)
    
    override func viewDidLoad() {
        super.viewDidLoad()
         //self.publishAndSubscribeExampleWithSink()
         //self.publishAndSubscribeExampleWithAssign()
        //self.subjectExampleOfCurrentSubject()
         self.zipExample()
  
    }
    
    // MARK:Simple Example of Publisher and sunscriber
    
    private func publishAndSubscribeExampleWithSink() {
        
        let _ = Just("Jageloo")
            .map { (value) -> String in
                return value
        }
        .sink { (receivedValue) in
            print(receivedValue)
        }
        
        // Here Just is a publisher which will only publish the output and falure type would be never.
        // map is the operator which transform the upstreams data and will do the functionality and return only output. This will not return any failure
        // Sink: This method creates the subscriber and immediately requests an unlimited number of values which will get the returned value from publisher
        
        
        // You can also write this like below
        
        /*  let publisher = Just(5)
         publisher.map({ (value) -> Int in
         return value
         })
         publisher.sink{ (receivedValue) in
         print(receivedValue)
         }*/
    }
    
    private func publishAndSubscribeExampleWithAssign() {
        self.cancellable = self.$labelAssignSubscriberValueString.receive(on: DispatchQueue.main)
            .assign(to: \.text, on: self.labelAssignSubscriber)
    }
    
    @IBAction func actionButtonTapped(_ sender: UIButton) {
        self.buttonTapCount = buttonTapCount + 1
        self.labelAssignSubscriberValueString = "You have tapped the button \(self.buttonTapCount) time"
    }
    
     
}

// MARK: Subject Example
extension ViewController  {
    
    func subjectExampleWithSendFunctionAndPublisher() {
        let subject = PassthroughSubject<String, Never>()
        
        let anyCancellable = subject
            .sink { value in
                print(value)
        }

        // This is a function which is always used to send values to the subscriber..
        subject.send("Sending first object")
        subject.send("Sending second object")
        
        /*
         //subscribe a subject to a publisher
         let _ = Just("world!")
         .subscribe(subject) */
        
        // If above function will be uncommented then below code will not be executed. Because of Just publisher. It only emits an output to each subscriber just once, and then finishes
        
        subject.send("Sending Third object")
        let _ = Just("Publishing the Value for subject")
            .subscribe(subject)
        anyCancellable.cancel()
        
        // AnyCanellable: AnyCancellable type erases a subscriber to the general form of Cancellable, This is most typically used when you want a reference to a subscriber to clean it up on deallocation.
        
    }
    
    func subjectExampleWithMultipleSubscriber() {
        
        let subject = PassthroughSubject<String, Never>()
        let publisher = subject.eraseToAnyPublisher()
        
        
        let subscriber1 = publisher.sink(receiveValue: { value in
            print(value)
        })
        
        //subscriber1 will recive the events but not the subscriber2
        subject.send("Event1")
        subject.send("Event2")
        
        
        let subscriber2 = publisher.sink(receiveValue: { value in
            print(value)
        })
        //Subscriber1 and Subscriber2 will recive this event
        subject.send("Event3")
    }
    
    func exposedTypeSubjectExample(){
        // Example of  exposed type complexity, if you created a publisher from a PassthroughSubject
        
        let exposedPassThroughSubjectResultType = PassthroughSubject<String, Never>()
            .flatMap { name in
                return Future<String, Error> { promise in
                    promise(.success(""))
                }.catch { _ in
                    Just("No user found")
                }.map { result in
                    return "\(result) foo"
                }
        }
        
        print(exposedPassThroughSubjectResultType)
        
        // ResulTyp output would be FlatMap<Map<Catch<Future<String, Error>, Just<String>>, String>, PassthroughSubject<String, Never>>(upstream: Combine.PassthroughSubject<Swift.String, Swift.Never>, maxPublishers: unlimited, transform: (Function))
        
        /* When you want to expose the subject, all of that composition detail can be very distracting and make your code harder to use. Two classes (AnySubscriber & AnyPublisher ) are used to expose simplified types for subscribers and publishers are.
         
         Two Every publisher also inherits a convenience method eraseToAnyPublisher() that returns an instance of AnyPublisher. eraseToAnyPublisher() is used very much like an operator, often as the last element in a chained pipeline, to simplify the type returned
         
         In below line of code we are using method easyToAnyPublisher for exposing the simplified publisher
         */
        
        let simplifiedExposedPassThroughSubjectResultType = PassthroughSubject<String, Never>()
            .flatMap { name in
                return Future<String, Error> { promise in
                    promise(.success(""))
                }.catch { _ in
                    Just("No user found")
                }.map { result in
                    return "\(result) foo"
                }
        }.eraseToAnyPublisher()
        
        
        print(simplifiedExposedPassThroughSubjectResultType)
        // ResulTyp output would be AnyPublisher which will be the type which is specified in passthroughsubject (Here <String, Never>)
        
        
    }
    
    func subjectExampleOfCurrentSubject() {
      
        // This will print currentvalue (Anuj) then wil print sending values
        let subject = CurrentValueSubject<String, Never>("Anuj")
        let publisher = subject.eraseToAnyPublisher()
    
        let anuj = publisher.sink(receiveValue: { value in
            print(value)
        })
        subject.send("Combine")
        subject.send("Swift")
    }
}

// MARK: Scan Example

extension ViewController {
    
    func scanExample()  {
        let _ = (0...5)
            .publisher
            .scan(0, { $0 + $1 })
            .sink(receiveValue: { print ("\($0)", terminator: " ") })
    }
    func reduceExample()  {
        let _ = (0...5)
            .publisher
            .reduce(0, { prevVal, newValueFromPublisher -> Int in
                 prevVal+newValueFromPublisher
            })
            .sink(receiveValue: { print ("\($0)", terminator: " ") })
        //self.scanExample()
    }

}

// MARK: combineLatest Example

extension ViewController {
    
    func combineLatestExample() {
        
        let usernamePublisher = PassthroughSubject<String, Never>()
        let passwordPublisher = PassthroughSubject<String, Never>()

        let validatedCredentials = Publishers.CombineLatest(usernamePublisher, passwordPublisher)
            .map { (username, password) -> (String, String) in
                return (username, password)
            }
            .map { (username, password) -> Bool in
                !username.isEmpty && !password.isEmpty && password.count > 12
            }
            .eraseToAnyPublisher()

        let firstSubscriber = validatedCredentials.sink { (valid) in
            print("First Subscriber: CombineLatest: Are the credentials valid: \(valid)")
        }

        let secondSubscriber = validatedCredentials.sink { (valid) in
            print("Second Subscriber: CombineLatest: Are the credentials valid: \(valid)")
        }

        // Nothing will be printed yet as `CombineLatest` requires both publishers to have send at least one value.
        usernamePublisher.send("avanderlee")
        passwordPublisher.send("weakpass")
        passwordPublisher.send("verystrongpassword")
      
        /*
        // Changing the type in publisher
         let usernamePublisher = PassthroughSubject<(String, Int), Never>()
               let passwordPublisher = PassthroughSubject<(String, Int), Never>()

               let validatedCredentials = Publishers.CombineLatest(usernamePublisher, passwordPublisher)
                   .map { (arg0, arg1) -> ((String, Int), (String, Int)) in
                       return (arg0, arg1)
                   }
                   .map { (arg0, arg1) -> Bool in
                       !arg0.0.isEmpty && !arg1.0.isEmpty && arg1.1 > 12
                   }
                   .eraseToAnyPublisher()

               let firstSubscriber = validatedCredentials.sink { (valid) in
                   print("First Subscriber: CombineLatest: Are the credentials valid: \(valid)")
               }

               let secondSubscriber = validatedCredentials.sink { (valid) in
                   print("Second Subscriber: CombineLatest: Are the credentials valid: \(valid)")
               }

               // Nothing will be printed yet as `CombineLatest` requires both publishers to have send at least one value.
               usernamePublisher.send(("avanderlee", 6))
               passwordPublisher.send(("weakpass", 13))
        */
         
        
    }
}

// MARK: Merge Example

extension ViewController {
    
    func mergeExample()  {
       
        let germanCities = PassthroughSubject<String, Never>()
        let italianCities = PassthroughSubject<String, Never>()
        let mergePublisher = Publishers.Merge(germanCities, italianCities)
            .map({ (value) -> String in
                return value
            })
        .eraseToAnyPublisher()
        let mergeSubscriber = mergePublisher.sink { (city) in
                     print("\(city) is a city in europe")
        }
        germanCities.send("Munich")
        italianCities.send("Milano")
    }
    
}

// MARK: Zip Example

extension ViewController {
    
    func zipExample() {
        
        let usernamePublisher = PassthroughSubject<String, Never>()
        let passwordPublisher = PassthroughSubject<String, Never>()

        let validatedCredentials = Publishers.Zip(usernamePublisher, passwordPublisher)
            .map { return $0}
        .sink { (mergedValue) in
        print("\(mergedValue)")
        }
        usernamePublisher.send("Rai55@32342")
        passwordPublisher.send("veryStrongPassword")
        passwordPublisher.send("veryStrongPassword2")
        usernamePublisher.send("AnujRai890888@3234909")

        
    }

}
