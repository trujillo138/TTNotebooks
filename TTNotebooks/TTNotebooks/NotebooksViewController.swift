//
//  NotebooksViewController.swift
//  TTNotebooks
//
//  Created by Tomas Trujillo on 3/21/15.
//  Copyright (c) 2015 TTApps. All rights reserved.
//

import UIKit
import CoreData

class NotebooksViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    // MARK: - Properties and outlets
    
    //  The collection view that will display all the outlets
    @IBOutlet weak var notebooksCollectionView: UICollectionView! {
        didSet {
            notebooksCollectionView.delegate = self
            notebooksCollectionView.dataSource = self
        }
    }
    
    //  The context of the application
    var context: NSManagedObjectContext? {
        didSet{
            self.updateNotebooks()
            self.notebooksCollectionView?.reloadData()
        }
    }
    
    //   An array of all the notebooks that the user has stored locally
    var notebooks = [Notebook]()
    
    //Variable representing the Notebook that is being edited
    var editedNotebook: Notebook?
    
    // MARK: - Localized Strings
    
    private struct LStrings {
        static let NewNotebookAlertTitle = NSLocalizedString("New Notebook", comment: "This is the title of the alert that will be displayed when the user wants to create a new Notebook in the library")
        static let NewNotebookAlertMessage = NSLocalizedString("What will be the name of your new Notebook", comment: "This is the message of the alert that will be displayed when the user wants to create a new Notebook in the library")
        static let NewNotebookAlertPlaceholder = NSLocalizedString("Name of the Notebook", comment: "This is the placeholder in the textfield of the alert that will be displayed when the user wants to create a new Notebook in the library and in it the user will type in the name of the new Notebook")
        static let NewNotebookCreateButton = NSLocalizedString("Create", comment: "This is the name of the button that will confirm the creation of a Notebook with the name given in the textfield of the alert that is displayed when the user wants to create a new Notebook")
        static let NewNotebookCancelButton = NSLocalizedString("Cancel", comment: "This is the name of the button that will cancel the creation of a Notebook with the name given in the textfield of the alert that is displayed when the user wants to create a new Notebook")
        static let EditNotebookAlertTitle = NSLocalizedString("Editing ", comment: "This is the name of the title for alert view when editing a Notebook")
        static let EditNotebookAlertDeleteButton = NSLocalizedString("Delete Notebook", comment: "This is the name of the button that will delete the Notebook that is being edited in the Notebooks View")
        static let EditNotebookAlertEditButton = NSLocalizedString("Edit Notebook", comment: "This is the name of the button that will edit the properties of the Notebook that is being edited in the Notebooks View")
    }
    
    // MARK: - Application Lifecycle
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        NSNotificationCenter.defaultCenter().addObserverForName(Constants.Notifications.UIDocumentReady, object: nil, queue: nil) { (note: NSNotification!) -> Void in
            if let uInf = note.userInfo {
                if let cntxt = uInf[Constants.Notifications.UIDocumentReadyUIContext] as? NSManagedObjectContext {
                    self.context = cntxt
                }
            }
        }
        updateViewAfterEdittingNotebooks()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: Constants.Notifications.UIDocumentReady, object: nil)
    }
    
    // MARK: - Actions
    
    //  Method that will update the array of notebooks with what it finds in the context
    func updateNotebooks() {
        if let ctxt = context {
            let request = NSFetchRequest(entityName: Constants.NotebookModel.EntityName)
            request.predicate = nil
            request.sortDescriptors = [NSSortDescriptor(key: Constants.NotebookModel.NotebookName, ascending: true, selector: "localizedCompare:")]
            notebooks = ctxt.executeFetchRequest(request, error: nil) as! [Notebook]
        }
    }
    
    //  Creates a notebook given a name
    func createNewNotebook(name: String) {
        if let newNotebook = NSEntityDescription.insertNewObjectForEntityForName(Constants.NotebookModel.EntityName, inManagedObjectContext: context!) as? Notebook {
            newNotebook.name = name
            
            if let notebookColor = NSUserDefaults.standardUserDefaults().valueForKey(Constants.SettingsVC.NotebookDefaultColor) as? Int {
                if notebookColor == Constants.SettingsVC.NotebookDefaultColorValue {
                    newNotebook.color = NSNumber(unsignedInt: arc4random_uniform(4))
                } else {
                    newNotebook.color = notebookColor
                }
            } else {
                newNotebook.color = NSNumber(unsignedInt: arc4random_uniform(4))
            }
            notebooks.append(newNotebook)
            notebooksCollectionView.reloadData()
        }
    }
    
    // Action that displays the alert in which the user will type the name of the notebook he/she wishes to create
    @IBAction func createNotebook(sender: UIBarButtonItem) {
        let alert = UIAlertController(title: LStrings.NewNotebookAlertTitle, message: LStrings.NewNotebookAlertMessage, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addTextFieldWithConfigurationHandler { (textField: UITextField!) -> Void in
            textField.placeholder = LStrings.NewNotebookAlertPlaceholder
        }
        alert.addAction( UIAlertAction(title: LStrings.NewNotebookCreateButton, style: UIAlertActionStyle.Default) { (_) -> Void in
            if let textField = alert.textFields?.first as? UITextField {
                self.createNewNotebook(textField.text)
            }
            })
        alert.addAction(UIAlertAction(title: LStrings.NewNotebookCancelButton, style: UIAlertActionStyle.Cancel, handler: nil))
        presentViewController(alert, animated: true, completion: nil)
    }
    
    // Displays an alert with the options to edit a Notebook
    func editNotebook (sender: UIGestureRecognizer ) {
        if let notebookCell = sender.view as? NotebookCollectionViewCell {
            if let ntbk = notebookCell.notebook {
                let alert = UIAlertController(title: LStrings.EditNotebookAlertTitle + ntbk.name, message: "", preferredStyle: UIAlertControllerStyle.ActionSheet)
                alert.addAction(UIAlertAction(title: LStrings.EditNotebookAlertEditButton, style: UIAlertActionStyle.Default) { (_) -> Void in
                    self.editedNotebook = ntbk
                    self.performSegueWithIdentifier(SegueIdentifiers.EditNotebookSegueIdentifier, sender: self)
                })
                alert.addAction(UIAlertAction(title: LStrings.EditNotebookAlertDeleteButton, style: UIAlertActionStyle.Destructive) { (_) -> Void in
                    self.context?.deleteObject(ntbk)
                    self.updateViewAfterEdittingNotebooks()
                    })
                alert.addAction(UIAlertAction(title: LStrings.NewNotebookCancelButton, style: UIAlertActionStyle.Cancel, handler: nil))
                dispatch_async(dispatch_get_main_queue()) {
                    self.presentViewController(alert, animated: true, completion: nil)
                }
            }
        }
    }
    
    // MARK: - UICollectionView Delegate Methods
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.notebooks.count
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCellWithReuseIdentifier(Constants.NotebooksVC.NotebookCellIdentifier, forIndexPath: indexPath) as? NotebookCollectionViewCell {
            let notebook = self.notebooks[indexPath.row]
            cell.notebook = notebook
            cell.name = notebook.name
            cell.backgroundColor = Helper.notebookColorForNumber(notebook.color.integerValue)
            cell.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: "editNotebook:"))
            return cell
        }
        return UICollectionViewCell()
    }
    
    func collectionView(collectionView: UICollectionView, shouldShowMenuForItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let width: CGFloat = min(Constants.NotebooksVC.NotebookWidth, view.bounds.width/3 - Constants.NotebooksVC.NotebookEdges*2)
        let height = Constants.NotebooksVC.NotebookHeight / Constants.NotebooksVC.NotebookWidth * width
        return CGSizeMake(width, height)
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return UIEdgeInsetsMake(8, Constants.NotebooksVC.NotebookEdges, 8, Constants.NotebooksVC.NotebookEdges)
    }
    
    // MARK: - Navigation

    private struct SegueIdentifiers {
        static let EditNotebookSegueIdentifier = "Edit Notebook"
    }
    
    func updateViewAfterEdittingNotebooks() {
        updateNotebooks()
        notebooksCollectionView.reloadData()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let ident = segue.identifier {
            switch (ident) {
            case SegueIdentifiers.EditNotebookSegueIdentifier :
                if let dvc = segue.destinationViewController as? EditNotebookViewController {
                    dvc.notebook = editedNotebook!
                }
            default :
                break
            }
        }
    }
    
}
