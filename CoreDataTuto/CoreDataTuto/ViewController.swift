//
//  ViewController.swift
//  CoreDataTuto
//
//  Created by Tejora on 18/07/18.
//  Copyright © 2018 Tejora. All rights reserved.
//

import UIKit
import CoreData

class ViewController: UIViewController {

    var managedObjectContext : NSManagedObjectContext?
    var taskArray: [NSManagedObject] = []
    @IBOutlet var tblView: UITableView!
    var fetchedResultsController: NSFetchedResultsController<Task>
    {
        var _fetchedResultsController: NSFetchedResultsController<Task>? = nil
        // If the variable is already initialized we return that instance.
        if _fetchedResultsController != nil {
            return _fetchedResultsController!
        }
        
        // If not lets build the required elements for the fetched
        // results controller.
        
        // First we need to create a fetch request with the pretended type.
        let fetchRequest: NSFetchRequest<Task> = Task.fetchRequest()
        
        // Set the batch size to a suitable number (optional).
        fetchRequest.fetchBatchSize = 20
        
        // Create at least one sort order attribute and type (ascending\descending)
        let sortDescriptor = NSSortDescriptor(key: "name", ascending: false)
        
        // Set the sort objects to the fetch request.
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        // Optionally, let's create a filter\predicate.
        // The goal of this predicate is to fetch Tasks that are not yet completed.
        let predicate = NSPredicate(format: "completed == FALSE")
        
        // Set the created predicate to our fetch request.
        fetchRequest.predicate = predicate
        
        // Create the fetched results controller instance with the defined attributes.
        let aFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext!, sectionNameKeyPath: nil, cacheName: nil)
        
        // Set the delegate of the fetched results controller to the view controller.
        // with this we will get notified whenever occours changes on the data.
        aFetchedResultsController.delegate = self
        
        // Setting the created instance to the view controller instance.
        _fetchedResultsController = aFetchedResultsController
        
        do {
            // Perform the initial fetch to Core Data.
            // After this step, the fetched results controller
            // will only retrieve more records if necessary.
            try _fetchedResultsController!.performFetch()
        } catch {
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
        
        return _fetchedResultsController!
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
      let appDelegateObj = UIApplication.shared.delegate as! AppDelegate
        managedObjectContext = appDelegateObj.persistaneContainerObj as? NSManagedObjectContext
        tblView.delegate = self
        tblView.dataSource = self
            self.fetchData()
        
       
        
    }

    @IBAction func addTaskAction(_ sender: Any) {
        
        guard let _context = managedObjectContext else {
            return
        }
        let object = NSEntityDescription.insertNewObject(forEntityName: "Task", into: self.managedObjectContext!) as! Task
        object.name = Date().description
        object.completed = false
        
        do{
            try _context.save()
        }catch{
            
        }
        self.tblView.reloadData()
    }
    
    //another way to fetch the data
    func fetchData()  {
        let predicate = NSPredicate(format: "completed == FALSE")
        let fetchRequest =
            NSFetchRequest<NSManagedObject>(entityName: "Task")
        fetchRequest.predicate = predicate
        do {
            taskArray = (try managedObjectContext?.fetch(fetchRequest))!
            print("taskArray count is \(taskArray.count)")
            
            for taskList in taskArray {
                var task = taskList as! Task
                print("name is ------------------------------------------ \(task.name)")
            }
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
    }
    
    
    
    
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

}
extension ViewController : NSFetchedResultsControllerDelegate
{
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        // Whenever a change occours on our data, we refresh the table view.
        self.tblView.reloadData()
    }
}

extension ViewController : UITableViewDelegate ,UITableViewDataSource {
    public func numberOfSections(in tableView: UITableView) -> Int
    {
        // We will use the proxy variable to our fetched results
        // controller and from that we try to get the sections
        // from it. If not available we will ignore and return none (0).
        return self.fetchedResultsController.sections?.count ?? 0
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        // We will use the proxy variable to our fetcehed results
        // controller and from that we try to get from that section
        // index access to the number of objects available.
        // If not possible, we will ignore and return 0 objects.
        return self.fetchedResultsController.sections?[section].numberOfObjects ?? 0
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        // First we get a cell from the table view with the identifier "Cell"
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        // Then we get the object at the current index from the fetched results controller
        let task = self.fetchedResultsController.object(at: indexPath)
        
        // And update the cell label with the task name
        cell.textLabel!.text = task.name
        
        // Finally we return the updated cell
        return cell
    }
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]?
    {
        // Whenever a user swipes a cell, we will show two options.
        // A option to mark a task completed.
        let completeAction = UITableViewRowAction(style: UITableViewRowActionStyle.normal, title: "Complete" , handler: { (action:UITableViewRowAction!, indexPath:IndexPath!) -> Void in
            self.markCompletedTaskIn(indexPath)
        })
        
        // And a option to delete a task.
        let deleteAction = UITableViewRowAction(style: UITableViewRowActionStyle.destructive, title: "Delete" , handler: { (action:UITableViewRowAction!, indexPath:IndexPath!) -> Void in
            self.deleteTaskIn(indexPath)
        })
        
        return [deleteAction, completeAction]
    }
    func markCompletedTaskIn(_ indexPath : IndexPath)
    {
        // To mark a task completed we retrieve the corresponding
        // object from the cell index.
        let task = self.fetchedResultsController.object(at: indexPath)
        
        // Update the attribute
        task.completed = true
        
        do {
            // And try to persist the change. If successfull
            // the fetched results controller will react and call the method
            // to reload the table view.
            try self.managedObjectContext?.save()
        } catch {}
        self.tblView.reloadData()
    }
    
    func deleteTaskIn(_ indexPath : IndexPath)
    {
        // To delete a task we retrieve the corresponding
        // object from the cell index.
        let task = self.fetchedResultsController.object(at: indexPath)
        
        // Then we use the managed object context and delete that object.
        self.managedObjectContext?.delete(task)
        
        do {
            // And try to persist the change. If successfull
            // the fetched results controller will react and call the method
            // to reload the table view.
            try self.managedObjectContext?.save()
        } catch {}
        self.tblView.reloadData()
    }
}
