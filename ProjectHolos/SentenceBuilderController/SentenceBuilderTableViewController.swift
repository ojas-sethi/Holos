//
//  SentenceBuilderTableViewController.swift
//  ProjectHolos
//
//  Created by Ojas Sethi on 22/03/19.
//  Copyright © 2019 Ojas Sethi. All rights reserved.
//

import UIKit
import Firebase
import AVKit
import AVFoundation
import FirebaseDatabase
import SwiftSpinner
import DGCollectionViewLeftAlignFlowLayout
import Pulsator

//import AlignedCollectionViewFlowLayout

class SentenceBuilderTableViewController:UIViewController ,UITableViewDelegate,UITableViewDataSource, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout,UIGestureRecognizerDelegate ,AVSpeechSynthesizerDelegate{
    
    // This static string constant will be the cellIdentifier for the
    // UITableViewCells holding the UICollectionView, it's important to append
    // "_section#" to it so we can understand which cell is the one we are
    // looking for in the debugger. Look in UITableView's data source
    // cellForRowAt method for more explanations about the UITableViewCell reuse
    // handling.
    
    
    // MARK: <Proprty & Variable>
    var refreshControl = UIRefreshControl()  //Set object of refreshcontroll
    var synthesizer = AVSpeechSynthesizer() // Set Object of speechSyntheiser

    
    static let tableCellID: String = "tableViewCellID_section_#"
    var currentTagPosition: CGRect!
    let numberOfSections: Int = 50
    let numberOfCollectionsForRow: Int = 1
    let numberOfCollectionItems: Int = 10000  //set the max value for words limit in category
    let tableViewRowHeight: CGFloat = 80
    
    let collectionTopInset: CGFloat = 5
    let collectionBottomInset: CGFloat = 5
    let collectionLeftInset: CGFloat = 1
    let collectionRightInset: CGFloat = 1
    
    var colorsDict: [Int: [UIColor]] = [:]
    var categoryArr = NSArray()
    var wordlistArr = NSDictionary()
    var textByCategoryDict =  NSMutableDictionary()
    var newRef : DatabaseReference?
    
    //Set object of CollectionView & TableView
    @IBOutlet weak var categotyTbl: UITableView!    //table view used to show category lisitng
    @IBOutlet weak var tagCollectioinView: UICollectionView!    //Colletion view used to show added words for seatnace formation and speak
    @IBOutlet weak var suggectionCollectionView: UICollectionView!    //Collection view used to show suggestion words
    
    //Set LongPressGesture Object for change the postion of tags
    fileprivate var longPressGesture: UILongPressGestureRecognizer!
    
    @IBOutlet weak var placeHolderView: UIView!
    @IBOutlet weak var speackBtn: UIButton!
    var audioPlayer: AVAudioPlayer!
    
    var textStr       = String()
    var str_arr       =  [String]()
    var suggestionArr = [Any]()
    
    /// Set true to enable UICollectionViews scroll pagination
    var paginationEnabled: Bool = true
    
    let pulsator = Pulsator()//Create a puls object for speaker button
    @IBOutlet weak var pulsView: UIView!
    var timer = Timer()
    var isResume = Bool()
    
    
    //MARK:<ViewLifeCycle>
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Uncomment the following line to preserve selection between
        // presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        // Uncomment the following line to display an Edit button in the
        // navigation bar for this view controller.
  
        // Set Collection View delegate
        tagCollectioinView.delegate   = self
        tagCollectioinView.dataSource = self
        suggectionCollectionView.dataSource = self
        suggectionCollectionView.delegate   = self
        
        //Set true to enable tagCollectionView for drag the cell
        tagCollectioinView.dragInteractionEnabled = true
        
        // Set up the flow layout's cell alignment:
        self.tagCollectioinView.collectionViewLayout = DGCollectionViewLeftAlignFlowLayout()//Set left alignment of the table view

        
        //Define the longPressGesture action method
        longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(self.handleLongGesture(gesture:)))
        tagCollectioinView.addGestureRecognizer(longPressGesture)
        
        
        (0 ... numberOfSections - 1).forEach { section in //Set Object for random color of word cell
            colorsDict[section] = randomRowColors() }
        
        refreshControl.addTarget(self, action: #selector(refresh(sender:)), for: UIControl.Event.valueChanged)
        categotyTbl.addSubview(refreshControl)
        
        synthesizer.delegate = self
        isResume = false
        
        //Pulssator is provide pulse effect when speack button running
        //it show three layer and fix radious
        pulsView.layer.addSublayer(pulsator)
        pulsator.backgroundColor = UIColor(red: 128/255, green: 0/255, blue: 128/255, alpha: 1).cgColor
        pulsator.radius = 40.0
        pulsator.numPulse = 3
    }

    override func viewWillAppear(_ animated: Bool) {
        
        if Connectivity.isConnectedToInternet() { // Check network connection
            GetCategoryData() // Calling category method
            categotyTbl.setContentOffset(.zero, animated: true) // Set table first index after refresh
            
            if str_arr.count > 0 {
                placeHolderView.isHidden = true
            }else {
                placeHolderView.isHidden = false
            }
            
            // do some tasks..
        }
        
        else {
            GetCategoryData()
            displayAlert(title: "Error", message: "Please check your internet connection", buttonTitle: "Try Again")
            print("Not connect" )
        }
    }
    
    //MARK:-Private Method

    //Pull to refresh
    @objc func refresh(sender:AnyObject) {
        
        //Call function for get category when user do refress the table
        GetCategoryData()
        categotyTbl.setContentOffset(.zero, animated: true)
        
    }
    
    
    // Set method to Get category from firebase
    func GetCategoryData() {
        newRef = Database.database().reference().child("categoryList")
        newRef?.observeSingleEvent(of: (.value), with: { snapshot in
            if !snapshot.exists() { return }
            self.categoryArr =  snapshot.value as! NSArray
            print(self.categoryArr)
            
            if self.categoryArr.count > 0 {
                self.getWordsBycategory()//Get wordlist bycategory
            }
        })
    }
    
    //Set Method to get Word from firebase
    func getWordsBycategory()  {
        textByCategoryDict.removeAllObjects()
        newRef = Database.database().reference().child("wordList")
        newRef?.observeSingleEvent(of: (.value), with: { snapshot in
            if !snapshot.exists() { return }

            if let Array = snapshot.value as? NSArray { //Check if Array come form firebase
                for (index,val) in Array.enumerated() {
                    let newVal    = val as? NSDictionary
                    let tempArray = NSMutableArray()
                    if newVal != nil {
                        for (_,testVal) in newVal!  {
                            tempArray.add(testVal)
                            
                        }
                    }
                    let swiftArray = tempArray as AnyObject as! [String]
                    let sortedArray = swiftArray.sorted { $0.localizedCaseInsensitiveCompare($1) == ComparisonResult.orderedAscending }

                    self.textByCategoryDict.setValue(sortedArray, forKey: "\(index)" ) //Set Array in dictionary by indexkey.
                }
                self.refreshControl.endRefreshing()

            }
            
            if let dictionary =  snapshot.value as? NSDictionary{//Check if Dictionary come from firebase
                for (index,val) in dictionary {
                    let newVal  = val as? NSDictionary
                    let tempArray = NSMutableArray() //Create tapmorayArray for words
                    
                    if newVal != nil {
                        for (_,testVal) in newVal!  {
                            tempArray.add(testVal)
                        }
                        
                    }
                    
                    self.textByCategoryDict.setValue(tempArray, forKey: "\(index)" ) //Word Adding in Dictionary (textBycategoryDict) and index use as key of dictionnary

                    print(self.textByCategoryDict)
                }
            }
            
            DispatchQueue.main.async { //update tableview in thread
            self.categotyTbl.reloadData()// Reload Tableview after get all words
            }

            
        })
    }
    
    //Method for longpress gesture . Reorder tag by longpress
    @objc func handleLongGesture(gesture: UILongPressGestureRecognizer) {
        switch(gesture.state) {
            
        case .began:
            guard let selectedIndexPath = tagCollectioinView.indexPathForItem(at: gesture.location(in:tagCollectioinView)) else {
                break
            }
            tagCollectioinView.beginInteractiveMovementForItem(at: selectedIndexPath)
        case .changed:
            tagCollectioinView.updateInteractiveMovementTargetPosition(gesture.location(in: gesture.view!))
        case .ended:
            tagCollectioinView.endInteractiveMovement()
        default:
            tagCollectioinView.cancelInteractiveMovement()
        }
    }

    //Tag Delete Method
    // Single tag delete when action on  cross button
    @objc func deleteUser(sender:UIButton) {
        
        if synthesizer.isSpeaking == true {//Check if Speaker is running
            
        }else {
            
            let index = sender.tag
            str_arr.remove(at: index)
            textStr = str_arr.joined(separator: " ")
            suggestionArr.removeAll()
            if str_arr.count > 0{ //check str_arr array count. if array is  empty than show tagview placeholder
                placeHolderView.isHidden = true
            }else {
                placeHolderView.isHidden = false
            }
            suggectionCollectionView.reloadData()
            tagCollectioinView.reloadData()
        }
     
    }
    
    
    //MARK:- Suggestion method  : It suggest the next sentance according to last sentance
    func suggestNextSentance(word:String)  {
        
        let str = word
        let augmentedStr = str + " *"
        let tc = UITextChecker()
        let range = NSRange(location: (str as NSString).length, length: -1)
        let maybeCompletions = tc.completions(forPartialWordRange: range,
                                              in: augmentedStr,
                                              language: "en_US")
        if let completions = maybeCompletions {
            if completions.isEmpty {
                print("Result was an empty Array.")
            } else {
                suggestionArr = completions
                for c in completions { print(str + " " + c) }
            }
            suggectionCollectionView.reloadData()
        } else {
            suggestionArr.removeAll()
            suggectionCollectionView.reloadData()
            print("Result was nil")
        }
    }
    
    //Method for Random color
    private final func randomRowColors() -> [UIColor] {
        let colors: [UIColor] = (0 ... numberOfCollectionItems - 1).map({ _ -> UIColor in
            var randomRed: CGFloat = CGFloat(arc4random_uniform(200))
            let randomGreen: CGFloat = CGFloat(arc4random_uniform(200))
            let randomBlue: CGFloat = CGFloat(arc4random_uniform(200))
            
            if randomRed == 255.0 && randomGreen == 255.0 && randomBlue == 255.0 {
                randomRed = CGFloat(arc4random_uniform(128))
            }
            
            let color: UIColor
            if #available(iOS 10.0, *) {
                if traitCollection.displayGamut == .P3 {
                    color = UIColor(displayP3Red: randomRed / 255.0, green: randomGreen / 255.0, blue: randomBlue / 255.0, alpha: 1.0)
                } else {
                    color = UIColor(red: randomRed / 255.0, green: randomGreen / 255.0, blue: randomBlue / 255.0, alpha: 1.0)
                }
            } else {
                color = UIColor(red: randomRed / 255.0, green: randomGreen / 255.0, blue: randomBlue / 255.0, alpha: 1.0)
            }
            
            return color
        })
        
        return colors
    }
    
    
    // AlertView Function
    func displayAlert(title: String, message: String, buttonTitle: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let alertAction = UIAlertAction(title: buttonTitle, style: .default, handler: nil)
        alertController.addAction(alertAction)
        self.present(alertController, animated: true, completion: nil)
    }

    /*
     // Uncomment the following method to to create default categories
    func createCategoryList() {
        newRef = Database.database().reference().child("categoryList")
        for (index, value) in  wordTypeSource.enumerated(){
            newRef?.child("\(index)").setValue(["category" : value as AnyObject, "categoryID" : index as AnyObject])
        }
    }
    */
    
    //MARK:- Action Method
    @IBAction func AddCategory_Action(_ sender: Any) {
        if synthesizer.isSpeaking != true {
            
            let nextController = self.storyboard?.instantiateViewController(withIdentifier: "ViewController") as! ViewController    //navigate Add category Controller
            self.navigationController?.pushViewController(nextController, animated: true)
        }
    }
    
    //Navigate About Controller
    @IBAction func about_Action(_ sender: Any) {
        if synthesizer.isSpeaking != true {
            
            let nextController = self.storyboard?.instantiateViewController(withIdentifier: "AboutViewController") as! AboutViewController
            self.navigationController?.pushViewController(nextController, animated: true)
        }
    }

    //Reset All Tags
    @IBAction func resetAllTag_Action(_ sender: Any) {
        if synthesizer.isSpeaking != true {
            
            str_arr.removeAll()
            suggestionArr.removeAll()
            textStr = ""
            if str_arr.count > 0 {
                placeHolderView.isHidden = true
            } else {
                placeHolderView.isHidden = false
            }
            
            tagCollectioinView.reloadData()//Reload Collection view after reset
            suggectionCollectionView.reloadData()
        }
    }
    
    //All tag will sound by this button
    @IBAction func Speak_Action(_ sender: Any) {
        
        if synthesizer.isSpeaking != true {
            
            pulsator.stop()
            if textStr == "" {
                displayAlert(title:"Alert" , message: "Please select atleast one word", buttonTitle: "Ok")
            } else {
                //Set Session
                do {
                    try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playAndRecord, mode: .default, options: .defaultToSpeaker)
                    try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
                } catch {
                    print("audioSession properties weren't set because of an error.")
                }
                //Set Speech Utterance object
                let utterance = AVSpeechUtterance(string: textStr)
                utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
                synthesizer = AVSpeechSynthesizer()
                utterance.rate = 0.37
    
                
                synthesizer.speak(utterance)
                
                pulsator.start()
                timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(checkSpeakerIsRunning) , userInfo: nil, repeats: true)
                
                
                do {
                    disableAVSession()    //Disable the session
                }
            }//else end
        }
        
        else {

            synthesizer.stopSpeaking(at: .immediate)
            isResume = true
            
        }
        
    }
    
    @objc func checkSpeakerIsRunning()  {
        
        if synthesizer.isSpeaking != true {
            timer.invalidate()
            pulsator.stop()
        }

    }
    
    private func disableAVSession() {
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("audioSession properties weren't disable.")
        }
    }
    
    //MARK:- Memory management
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension String {
    func widthOfString(usingFont font: UIFont) -> CGFloat {
        let fontAttributes = [NSAttributedString.Key.font: font]
        let size = self.size(withAttributes: fontAttributes)
        return size.width
    }
}

extension String {
    var urlEncoded: String {
        return
            self.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
    }
}

// MARK: Category List <UITableView Data Source and Delegate>
extension SentenceBuilderTableViewController {
    
    func numberOfSections(in _: UITableView) -> Int {
        return categoryArr.count
    }
    
    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Instead of having a single cellIdentifier for each type of
        // UITableViewCells, like in a regular implementation, we have multiple
        // cellIDs, each related to a indexPath section. By Doing so the
        // UITableViewCells will still be recycled but only with
        // dequeueReusableCell of that section.
        //
        // For example the cellIdentifier for section 4 cells will be:
        //
        // "tableViewCellID_section_#3"
        //
        // dequeueReusableCell will only reuse previous UITableViewCells with
        // the same cellIdentifier instead of using any UITableViewCell as a
        // regular UITableView would do, this is necessary because every cell
        // will have a different UICollectionView with UICollectionViewCells in
        // it and UITableView reuse won't work as expected giving back wrong
        // cells.
        
        var cell: CollectionTableViewCell? = tableView.dequeueReusableCell(withIdentifier: SentenceBuilderTableViewController.tableCellID + indexPath.section.description) as? CollectionTableViewCell
        
        
        if cell == nil {
            cell = CollectionTableViewCell(style: .default, reuseIdentifier: SentenceBuilderTableViewController.tableCellID + indexPath.section.description)
            
            // Configure the cell...
            cell?.selectionStyle = .none
            cell?.collectionViewPaginatedScroll = paginationEnabled
        }
        
        cell?.collectionView.tag = indexPath.section
        return cell!
    }
    
    func tableView(_: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        let dict =  categoryArr[section] as? NSDictionary
        return dict!["category"] as? String    //"Section: " + section.description
    }
    func tableView(_: UITableView, heightForRowAt _: IndexPath) -> CGFloat {
        return tableViewRowHeight
    }
    
    func tableView(_: UITableView, heightForHeaderInSection _: Int) -> CGFloat {
        return 28
    }
    
    func tableView(_: UITableView, heightForFooterInSection _: Int) -> CGFloat {
        return 0.0001
    }
    
    func tableView(_: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let cell: CollectionTableViewCell = cell as? CollectionTableViewCell else {
            return
        }
    
        cell.collectionView.backgroundColor = UIColor(red: 247.0/255, green: 245.0/255, blue: 237.0/255, alpha: 1.0)
        cell.setCollectionView(dataSource: self, delegate: self, indexPath: indexPath)
    }

}

// MARK: <UICollectionView Delegate and Data Source >
extension SentenceBuilderTableViewController {
    
    // We have two collection view and three collectionview cell, each cell have diffrent identifier instead of single identifier.
    
    //** TagCollection View :- it is used to create tag sentance. Tag is added when user choose the words
    // Tag collection allow re-order the cell (change the postion of cell) and also change the indexing of array accoding to current cell postion
    // Tag collectionview allow to delete single tag  and delete all tag.
    // Signle tag delete:- Signle tag delete by tag button which is exist left side of the tag
    // Delete all tag: We can delete all tag by reset button, Reset button is exist on header
    // Speak Tag :- Afetr selected all tag than we can heard it by speaker button,when click on speak button all
    // all tag will start speak whatever order they are
    
    //** Suggestion Collection View :- Suggestion colectionview show the suggestion according to last tag selection. like that user create have tag than suggestion collection view show have a good, Have a nice etc.
    // Suggestion collection view also allow to create tag , when we select on suggestion than it will show in tagcollection view as tag.
    
    //** IndexedCollectionViewCell:- this cell is initialize inside of tableview view. tableview scroll both side left to right and top to bottom
    // When we click on indexedCollectionCell (as sentance cell) than tag is create inside tag collection view
    
    func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
        if collectionView == tagCollectioinView {
            return true
        } else {
            return false
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        
        if collectionView == tagCollectioinView {
            let item = str_arr.remove(at: sourceIndexPath.item)
            str_arr.insert(item, at: destinationIndexPath.item)
            textStr = str_arr.joined(separator: " ")
            tagCollectioinView.reloadData()
            print(str_arr)
        }
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
     
        if collectionView == tagCollectioinView {
            return 1
        } else if collectionView == suggectionCollectionView {
            return 1
        } else {
            return categoryArr.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if collectionView == tagCollectioinView {
            return str_arr.count
        } else if collectionView == suggectionCollectionView {
            return suggestionArr.count
        } else {
            let catIdict = categoryArr[collectionView.tag] as? NSDictionary
            if catIdict != nil {
                let id = catIdict?["categoryID"] as! Int
                if section == id {
                    print(textByCategoryDict["\(id)"] ?? "")
                    let countArr = textByCategoryDict["\(id)"] as? NSArray
                    print(countArr?.count  ??  0)
                    return countArr?.count ?? 0
                } else {
                    return 0
                }
            } else {
                return 0
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if collectionView == tagCollectioinView {
            
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TagCollectionCell", for: indexPath as IndexPath) as! TagCollectionCell

            if str_arr.count > 0 {
                placeHolderView.isHidden = true
            }
            else{
                placeHolderView.isHidden = false
            }
            
            cell.tagNameLbl.text  = str_arr[indexPath.row]
            cell.backgroundColor = UIColor.cyan // make cell
            cell.tagRemoveBtn.tag = indexPath.row
            cell.tagRemoveBtn.addTarget(self, action: #selector(deleteUser), for: UIControl.Event.touchUpInside) //Add target for delete tag
            cell.layer.cornerRadius = 10
            cell.clipsToBounds = true
            
            return cell
            
        } else if collectionView == suggectionCollectionView {
            
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SuggestionCell", for: indexPath as IndexPath) as! SuggestionCell
            cell.lblName.text = suggestionArr[indexPath.row] as? String
            cell.clipsToBounds = true
            return cell
        } else {
            
            guard let cell: IndexedCollectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: IndexedCollectionViewCell.identifier, for: indexPath) as? IndexedCollectionViewCell else {
                fatalError("UICollectionViewCell must be of IndexedCollectionViewCell type")
            }
            
            guard let indexedCollectionView: IndexedCollectionView = collectionView as? IndexedCollectionView else {
                fatalError("UICollectionView must be of IndexedCollectionView type")
            }
            
            cell.layer.cornerRadius = 10
            cell.clipsToBounds = true
            let catIdict = categoryArr[indexedCollectionView.indexPath.section] as? NSDictionary
            let id = catIdict?["categoryID"] as! Int
            let countArr = textByCategoryDict["\(id)"] as? NSArray
            cell.setLabelText(countArr![indexPath.row ] as! String)
            cell.backgroundView?.backgroundColor = UIColor.gray
            cell.backgroundColor = colorsDict[indexedCollectionView.indexPath.section]?[indexPath.row]
            
            return cell
        }
    }
    
    // MARK: <UICollectionViewDelegate Flow Layout>
    func collectionView(_ collectionView: UICollectionView, layout _: UICollectionViewLayout, insetForSectionAt _: Int) -> UIEdgeInsets {
        
        if collectionView == tagCollectioinView {
            return UIEdgeInsets(top:5, left:12, bottom:35, right:12)
        } else if collectionView == suggectionCollectionView {
            return UIEdgeInsets(top:5, left:5, bottom:5, right:5)
        } else {
            return UIEdgeInsets(top:5, left:0, bottom:5, right:0)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout _: UICollectionViewLayout, sizeForItemAt  indexPath: IndexPath) -> CGSize {
    
        //Dynamically set cell label width
        if collectionView == tagCollectioinView {
            
            let label = UILabel(frame: CGRect.zero)
            label.text = str_arr[indexPath.item]
            label.sizeToFit()
            
            let tagLabelSize = label.frame.width + 50
            if tagLabelSize > self.tagCollectioinView.frame.width {
                return CGSize(width:340, height: 40 )// If cell label width is greater than screen so fix the cell size
            }
            else {
                return CGSize(width: label.frame.width + 70, height: 40)// set cell width is dynamically
            }
        } else if collectionView == suggectionCollectionView {
            
            let label = UILabel(frame: CGRect.zero)
            label.sizeToFit()
            let size = ( suggestionArr[indexPath.row] as! NSString).size(withAttributes: nil)
            let tableViewCellHeight: CGFloat = tableViewRowHeight//tableView.rowHeight
            let collectionItemWidth: CGFloat = tableViewCellHeight - (collectionLeftInset + collectionRightInset)
            let collectionViewHeight: CGFloat = collectionItemWidth
            return CGSize(width: collectionItemWidth + 50 , height: 50 )
            
        } else {
            
            let label = UILabel(frame: CGRect.zero)
            guard let indexedCollectionView: IndexedCollectionView = collectionView as? IndexedCollectionView else {
                fatalError("UICollectionView must be of IndexedCollectionView type")
            }
            
            let catIdict = categoryArr[indexedCollectionView.indexPath.section] as? NSDictionary
            let id = catIdict?["categoryID"] as! Int
            let countArr = textByCategoryDict["\(id)"] as? NSArray
            label.text =   countArr![indexPath.row ] as? String
            label.sizeToFit()
            let size = ( label.text)?.size(withAttributes: nil)
            
            let tableViewCellHeight: CGFloat = tableViewRowHeight//tableView.rowHeight
            let collectionItemWidth: CGFloat = tableViewCellHeight - (collectionLeftInset + collectionRightInset)
            
            let collectionViewHeight: CGFloat = collectionItemWidth
            let cellSize =  collectionItemWidth + size!.width
    
            if cellSize > indexedCollectionView.frame.width {
                return CGSize(width:355, height: collectionViewHeight - 30 )
            } else {
                return CGSize(width: cellSize - 10   , height: collectionViewHeight - 30  )
            }
        }
        
    }
    
    func collectionView(_ collection: UICollectionView, layout _: UICollectionViewLayout, minimumLineSpacingForSectionAt _: Int) -> CGFloat {

        if collection == tagCollectioinView {
            return 5
        } else {
            return 5
        }
    }
    
    func collectionView(_ collection: UICollectionView, layout _: UICollectionViewLayout, minimumInteritemSpacingForSectionAt _: Int) -> CGFloat {
        
        if collection == tagCollectioinView {
            return 5
        }
        return 5
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {

        if synthesizer.isSpeaking != true {
            
            if collectionView == tagCollectioinView {
                // do in case of tagCollectionView
            } else if collectionView == suggectionCollectionView {
                let str =  suggestionArr[indexPath.row]
                str_arr.append(str as! String)
                suggestNextSentance(word: str as! String ) //Calling Suggesstion function
                textStr = str_arr.joined(separator: " ")
                tagCollectioinView.reloadData()
            } else {
                guard let indexedCollectionView: IndexedCollectionView = collectionView as? IndexedCollectionView else {
                    fatalError("UICollectionView must be of IndexedCollectionView type")
                }
                
                let catIdict = categoryArr[collectionView.tag] as AnyObject
                print(catIdict)
                let id = catIdict["categoryID"] as! Int
                let countArr = textByCategoryDict["\(id)"] as! NSArray
                print(indexPath.row)
                let word =  countArr[indexPath.row]
                print(word)
                
                // Collection view scroll and show it from bottom when it update  with new item
                let item = self.collectionView(self.tagCollectioinView!, numberOfItemsInSection: 0) - 1
                let lastItemIndex = NSIndexPath(item: item, section: 0)
                self.tagCollectioinView?.scrollToItem(at: lastItemIndex as IndexPath, at: UICollectionView.ScrollPosition.top, animated: false)
                
                //Calling Suggesstion function
                suggestNextSentance(word: word as? String ?? "")
                
                str_arr.append(word as! String)
                textStr = str_arr.joined(separator: " ")//Sepration string by blank space
                tagCollectioinView.reloadData()
            }
        }
    }
    
}
