//
//  ViewController.swift
//  ProjectHolos
//
//  Created by Ojas Sethi on 22/12/18.
//  Copyright © 2018 Ojas Sethi. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase


class ViewController: UIViewController , UITextFieldDelegate ,UICollectionViewDataSource,UICollectionViewDelegate,UICollectionViewDelegateFlowLayout {
    
    // MARK: <Proprty & Variable>
    @IBOutlet weak var categoryCollectionView: UICollectionView!
    private let wordTypeSource = ["Greetings", "Feelings", "Verbs", "Vowels", "Objects", "Nouns" ]
    @IBOutlet weak var wordTextField:UITextField!
    @IBOutlet weak var addWordButton: UIButton!
    @IBOutlet var customAlertView: UIView!
    @IBOutlet weak var lblAlert: UILabel!
    
    
    // Used to communicate with the Firebase Database
    var ref : DatabaseReference!
//    var wordTypeSelection : String!
    var newRef : DatabaseReference?
//    var wordListArray = [String]()
    var categoryArr = NSArray()
    var catIndex = Int()
    var isfirstTime = Bool()
    
    //MARK:- Viewlife cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        wordTextField.delegate = self
        self.hideKeyboardWhenTappedAround()// hide keyboard
        
        categoryCollectionView.dataSource = self
        categoryCollectionView.delegate   = self
        isfirstTime = false // Set false when view load
        
        self.wordTextField.adjustsFontSizeToFitWidth = true
        self.wordTextField.minimumFontSize = 10.0
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if Connectivity.isConnectedToInternet() { // Check Network Connection
            self.GetCategoryData()// Calling category method
            // do some tasks..
        }
        else {

        lblAlert.text = "Please check your internet connection" // Set text for alertview
        CustomAlert()//Call alertview
        
        }
    }
    
    //MARK:- Action Method
    //Back Navigation
    @IBAction func back_Action(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    @IBAction func addWordPressed(_ sender: Any) {
        wordTextField.text  = wordTextField.text?.trimmingCharacters(in: .whitespaces)

        if wordTextField.text == "" {
            
            lblAlert.text = "Please enter a word"
            CustomAlert()
            
        } else {
            findWord()
        }
    }
    
    //MARK:- Private Method
    //MARK:- TextField Delegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return true
    }
    
    // Checking if word already exist
    func findWord() {
        let newReference = Database.database().reference().child("wordList")
        let query = newReference.queryOrdered(byChild: "word").queryEqual(toValue: wordTextField.text!)
        query.observeSingleEvent(of: .value) { (snapshot) in
            if snapshot.exists() {
                print("Word exists in database.")

                self.lblAlert.text = "Word already exists in the database. Try again."
                self.CustomAlert()

            } else {
                print("Word does not exist in database.")
                self.wordsUpdate() // Call method if word not exist
            }
        }
    }
    
    //Word insert in database
    func wordsUpdate() {
        if isfirstTime == true { // If category is selected not selected than go inside other show alert
            newRef = Database.database().reference()
            newRef?.child("wordList").child("\(catIndex)").childByAutoId().setValue(wordTextField.text)
            CustomAlert()
            wordTextField.text = "" // textfield empty after word successfully added
            
        }else {

            lblAlert.text = "Please select category"
            CustomAlert()
            
        }
    }
    //Get category method
    func GetCategoryData() {
        
        newRef?.observeSingleEvent(of: (.value), with: { snapshot in
            if !snapshot.exists() { return }
            self.categoryArr =  snapshot.value as! NSArray // Set all category in array But Currently it is not using in the code
        })
        
        let newReference = Database.database().reference().child("wordList")
        newReference.observeSingleEvent(of: (.value), with: { snapshot in
            if !snapshot.exists() { return }
            print(snapshot.value!)
            print(self.categoryArr)
        })
    }
    
    // Alert Function
    func displayAlert(title: String, message: String, buttonMessage: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let alertAction = UIAlertAction(title: buttonMessage, style: .default, handler: nil)
        
        alertController.addAction(alertAction)
        self.present(alertController, animated: true, completion: nil)
    }
}

extension ViewController {
    //<MARK:- Clooection View Datasource and delegate>
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
        
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return wordTypeSource.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AddWordCell", for: indexPath as IndexPath) as! AddWordCell
        cell.LblCategoryName.text = wordTypeSource[indexPath.row]
        
        if isfirstTime == true {
            let backgroundView = UIView()
            backgroundView.backgroundColor = UIColor.gray
            cell.selectedBackgroundView = backgroundView
        } else {
            let backgroundView = UIView()
            backgroundView.backgroundColor =  UIColor.purple
            cell.selectedBackgroundView = backgroundView
        }
        
        return cell
        
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        isfirstTime = true
        catIndex = indexPath.row
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 20
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 20;
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: ( self.categoryCollectionView.frame.size.width - 200 ) / 2 ,height:( self.categoryCollectionView.frame.size.width - 300 ) / 2)
    }


    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 20, bottom: 20, right: 20)
    }

    func CustomAlert()  {

        self.customAlertView.alpha = 1
        customAlertView.frame = CGRect.init(x: 0, y: 100, width: 250, height: 40)
        customAlertView.backgroundColor = UIColor.white     //give color to the view
        customAlertView.center = self.view.center
        self.customAlertView.layer.cornerRadius = 8;
        self.view.addSubview(customAlertView)
        UIView.animate(withDuration: 2) {
            self.customAlertView.alpha = 0
        }
    
    }
}
extension UIViewController {
    func hideKeyboardWhenTappedAround() {
        //        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action:    #selector(UIViewController.dismissKeyboard))
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}
