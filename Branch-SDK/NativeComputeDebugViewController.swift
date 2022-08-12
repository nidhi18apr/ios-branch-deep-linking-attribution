import UIKit

@objc public class NativeComputeDebugViewController: UITableViewController {
    
    @objc public var schemaMap : [String:Any] = [String:Any]()
    let bncNative = Branch.getInstance().bncNative
        
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.estimatedRowHeight = 150.0
        self.tableView.rowHeight = UITableView.automaticDimension
        
        self.tableView.register(NativeComputeDebugCell.self, forCellReuseIdentifier: "NativeComputeDebugCell")
        self.tableView.register(NativeComputeDebugButtonCell.self, forCellReuseIdentifier: "NativeComputeDebugButtonCell")
        self.tableView.dataSource = self
        self.tableView.delegate = self
        
        //dismiss view when app goes in background
        let backgorundNotificationCenter = NotificationCenter.default
        backgorundNotificationCenter.addObserver(self, selector:#selector(appMovedToBackground), name: UIApplication.willResignActiveNotification, object: nil)

    }
    
    @objc func appMovedToBackground() {
        self.presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    
    
    // MARK: - helpers
    func arrayDict(for section: Int) -> [String: Any] {
        let sections = schemaMap["sections"] as! [Any]
        return sections[section] as! [String: Any]
    }

    func items(in section: Int) -> [[String: Any]] {
        let arrayDict = self.arrayDict(for: section)
        return arrayDict["values"] as! [[String: Any]]
    }

    func item(at indexPath: IndexPath) -> [[String: Any]] {
        return self.items(in: indexPath.section)
    }
    
    func runWorkflow(indexPath: IndexPath) -> Void {
        let dict = self.arrayDict(for: indexPath.section)
        let actions = dict["actions"] as! [[String:Any]]
        for action in actions {
            self.bncNative.runWorkflow(input: action)
        }
    }
    
    @objc public func schemaMap(schemaMap: [String:Any]) {
        self.schemaMap = schemaMap
    }
}

// MARK: - UITableViewDelegate and UITableViewDataSource
extension NativeComputeDebugViewController {
    public override func numberOfSections(in tableView: UITableView) -> Int {
        let sections = schemaMap["sections"] as! [Any]
        return sections.count
    }
    
    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
           return 1
        }

    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let values = item(at: indexPath)
        var cellText = ""
        do {
            let prettyJsonData = try JSONSerialization.data(withJSONObject: values, options: .prettyPrinted)
            let prettyPrintedJson = String(data: prettyJsonData, encoding: .utf8)
            cellText = prettyPrintedJson!
        }
        catch let error as NSError {
            print("Found an error - \(error)")
        }
        
        let content = self.arrayDict(for: indexPath.section)
        let keyExists = content["actions"] != nil
        if !keyExists {
            let cell = tableView.dequeueReusableCell(withIdentifier: "NativeComputeDebugCell", for: indexPath) as! NativeComputeDebugCell
            cell.textView.text = cellText
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "NativeComputeDebugButtonCell", for: indexPath) as! NativeComputeDebugButtonCell
            cell.textView.text = cellText
            cell.buttonTapCallback = {
                print("button clicked")
                self.runWorkflow(indexPath: indexPath)
                let alert = UIAlertController(title: "Alert", message: "All config urls processed", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
            return cell
        }

    }
    
    
    public override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let section = self.arrayDict(for: section)
        return section["name"] as? String
   }
    
    public override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
       return UITableView.automaticDimension
   }
    
    override public func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {

        if let view = view as? UITableViewHeaderFooterView {
            view.textLabel?.backgroundColor = .clear
            view.textLabel?.textColor = .black
        }
    }
    
    

}

    
    
