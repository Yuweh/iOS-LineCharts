

// discontinued development - stashed here for other's referrence XD

//
//  GraphView.swift
//  DailyGraphTodayExt
//
//  Created by Francis Jemuel Bergonia on 8/14/19.
//


import UIKit

@IBDesignable class GraphView: UIView {
    
    private struct Constants {
        static let cornerRadiusSize = CGSize(width: 8.0, height: 8.0)
        static let margin: CGFloat = 20.0
        static let topBorder: CGFloat = 60
        static let bottomBorder: CGFloat = 50
        static let colorAlpha: CGFloat = 0.3
        static let circleDiameter: CGFloat = 5.0
    }
    
    //sample data
    var graphPoints: [Int] = [40, 200, 65, 90, 50, 80, 30, 40, 120, 160, 40, 50, 80, 150]
    
    override func draw(_ rect: CGRect) {
        
        let width = rect.width
        let height = rect.height
        
        let path = UIBezierPath(roundedRect: rect,
                                byRoundingCorners: UIRectCorner.allCorners,
                                cornerRadii: Constants.cornerRadiusSize)
        path.addClip()
        
        //calculate the x point
        let margin = Constants.margin
        let columnXPoint = { (column:Int) -> CGFloat in
            //Calculate gap between points
            let spacer = (width - margin * 2 - 4) / CGFloat((self.graphPoints.count - 1))
            var x: CGFloat = CGFloat(column) * spacer
            x += margin + 2
            return x
        }
        
        // calculate the y point
        let topBorder: CGFloat = Constants.topBorder
        let bottomBorder: CGFloat = Constants.bottomBorder
        let graphHeight = height - topBorder - bottomBorder
        let maxValue = 300 // 300 mg/dL Glucose Max Value
        let columnYPoint = { (graphPoint:Int) -> CGFloat in
            var y:CGFloat = CGFloat(graphPoint) / CGFloat(maxValue) * graphHeight
            y = graphHeight + topBorder - y // Flip the graph
            return y
        }
        
        // set color to the line graph
        UIColor.white.setFill() // for pointer
        UIColor.white.setStroke() // for lines
        
        //set up the points line
        let graphPath = UIBezierPath()
        //go to start of line
        graphPath.move(to: CGPoint(x:columnXPoint(0), y:columnYPoint(graphPoints[0])))
        
        //add points for each item in the graphPoints array
        //at the correct (x, y) for the point
        for i in 1..<graphPoints.count {
            let nextPoint = CGPoint(x:columnXPoint(i), y:columnYPoint(graphPoints[i]))
            graphPath.addLine(to: nextPoint)
        }
        
        
        //draw the line in between
        graphPath.lineWidth = 2.0
        graphPath.stroke()
        
        //Draw the circles on top of graph stroke
        for i in 0..<graphPoints.count {
            var point = CGPoint(x:columnXPoint(i), y:columnYPoint(graphPoints[i]))
            point.x -= Constants.circleDiameter / 2
            point.y -= Constants.circleDiameter / 2
            
            let circle = UIBezierPath(ovalIn: CGRect(origin: point, size: CGSize(width: Constants.circleDiameter, height: Constants.circleDiameter)))
            circle.fill()
        }
        
        //Draw horizontal graph lines on the top of everything
        let linePath = UIBezierPath()
        
        //top line
        linePath.move(to: CGPoint(x:margin, y: topBorder))
        linePath.addLine(to: CGPoint(x: width - margin, y:topBorder))
        
        //center line
        linePath.move(to: CGPoint(x:margin, y: graphHeight/2 + topBorder))
        linePath.addLine(to: CGPoint(x:width - margin, y:graphHeight/2 + topBorder))
        
        //bottom line
        linePath.move(to: CGPoint(x:margin, y:height - bottomBorder))
        linePath.addLine(to: CGPoint(x:width - margin, y:height - bottomBorder))
        let color = UIColor(white: 1.0, alpha: Constants.colorAlpha)
        color.setStroke()
        
        linePath.lineWidth = 1.0
        linePath.stroke()
    }
}


// end of GraphView,.swift here

//
//  TodayViewController.swift
//  DailyGraphTodayExt
//
//  Created by Francis Jemuel Bergonia on 8/14/19.
//

import UIKit
import NotificationCenter

class MenuTodayTableViewCell: UITableViewCell {
}

class GraphTodayTableViewCell: UITableViewCell {
}

class TodayViewController: UIViewController, NCWidgetProviding {
    
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var expandedGraphView: GraphView!
    @IBOutlet weak var graphViewHeightValue: NSLayoutConstraint!
    
    //For compact view
    @IBOutlet weak var compactGlucoseUserInput: UILabel!
    
    //For expanded view
    @IBOutlet weak var glucoseMaxValue: UILabel!
    @IBOutlet weak var glucoseUserInput: UILabel!
    @IBOutlet weak var lastInputLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        // set widget Show options
        if #available(iOSApplicationExtension 10.0, *) {
            extensionContext?.widgetLargestAvailableDisplayMode = .expanded
        }
        // set tableView configurations
        self.configTableView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // set graph subviews to be redrawn
        self.updateExpandedGraph()
        self.loadLastInput()
    }
    
    // MARK: - NCWidgetProviding
    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        // Perform any setup necessary in order to update the view.
        
        // If an error is encountered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData
        
        completionHandler(NCUpdateResult.newData)
    }
    
    func widgetMarginInsets(forProposedMarginInsets defaultMarginInsets: UIEdgeInsets) -> (UIEdgeInsets) {
        return UIEdgeInsets.zero
    }
    
    @available(iOSApplicationExtension 10.0, *)
    func widgetActiveDisplayModeDidChange(_ activeDisplayMode: NCWidgetDisplayMode, withMaximumSize maxSize: CGSize) {
        
        // 1 - animates graphView to flip if Show options was tapped
        UIView.transition(from: expandedGraphView,
                          to: expandedGraphView,
                          duration: 1.0,
                          options: [.transitionFlipFromLeft, .showHideTransitionViews],
                          completion:nil)
        
        if activeDisplayMode == .expanded {
            //2 - set container to height: 230 from compact size
            self.graphViewHeightValue.constant = 230
            preferredContentSize = CGSize(width: maxSize.width, height: 200)
            self.showHideGraphLabels(false)
        } else if activeDisplayMode == .compact {
            preferredContentSize = maxSize
            //3 - indicate that the graph needs to be redrawn
            self.graphViewHeightValue.constant = 110
            self.updateExpandedGraph()
            self.showHideGraphLabels(true)
        }
        
        self.loadLastInput()
    }
    
    func updateExpandedGraph() {
        // set to prioritize refreshing the graphView
        DispatchQueue.main.async {
            self.expandedGraphView.setNeedsDisplay()
        }
    }
    
    func showHideGraphLabels(_ hide: Bool) {
        // show or hide graph labels depending on the activeDisplayMode
        self.glucoseMaxValue.isHidden = hide
        self.lastInputLabel.isHidden = hide
        self.glucoseUserInput.isHidden = hide
        self.compactGlucoseUserInput.isHidden = !hide
    }
    
    func loadLastInput() {
        
        // get date today
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yyyy"
        
        // generate key for retrieving
        let glucoseDateStampKey = ("\(formatter.string(from: date))-InputGlucoseDateStampKey")
        let glucoseTimeStampArrayKey = ("\(formatter.string(from: date))-InputGlucoseDateStampArrayKey")
        
        // set DataSharing for data retrieval from Main App
        if let sharedDefaults: UserDefaults = UserDefaults(suiteName:"group.jp.co.arkray.e-SMBG") {
            let timeStampsArray = sharedDefaults.object(forKey: glucoseTimeStampArrayKey) as! [String]
            let tempArray = sharedDefaults.object(forKey: glucoseDateStampKey)
            
            //self.glucoseUserInput.text = timeStampsArray[0]
            
            // for checking
            print("ForTodayExtension- timeStampsArray@Ext: \(String(describing: timeStampsArray))")
            print("ForTodayExtension- timeStampsArray@Ext: \(String(describing: timeStampsArray))")
            
        }
        
    }
}

extension TodayViewController: UITableViewDelegate, UITableViewDataSource {
    
    private func configTableView() {
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.tableView.register(UINib(nibName: "MenuTodayTableViewCell", bundle: nil), forCellReuseIdentifier: "MenuTodayTableViewCell")
        self.tableView.register(UINib(nibName: "GraphTodayTableViewCell", bundle: nil), forCellReuseIdentifier: "GraphTodayTableViewCell")
        self.tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.row == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "MenuTodayTableViewCell") as! MenuTodayTableViewCell
            // Set up cell.label
            return cell
        } else if indexPath.row == 1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "GraphTodayTableViewCell") as! GraphTodayTableViewCell
            // Set up cell.button
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "thirdTableCell") as! MenuTodayTableViewCell
            // Set up cell.textField
            return cell
        }
    }
    
    
    
    
}

//end of TodayViewController here

-(void)saveInputGlucoseForTodayExtension: (NSString*)userGlucoseInput
{
    //get dateToday
    NSDate *dateToday = [[NSDate alloc]init];
    
    // get current date today as String
    NSDateFormatter* localDate = [[NSDateFormatter alloc] init] ;
    [localDate setTimeZone:[NSTimeZone systemTimeZone]];
    [localDate setDateFormat:@"MM/dd/yyyy"];
    NSString* localDateString = [localDate stringFromDate:dateToday];
    
    // get current time today as String
    NSDateFormatter* localTime = [[NSDateFormatter alloc] init];
    [localTime setTimeZone:[NSTimeZone systemTimeZone]];
    [localTime setDateFormat:@"hh:mm a"];
    NSString* localTimeString = [localTime stringFromDate:dateToday];
    
    // set key for saving
    NSString* glucoseTimeStampKey = [localTimeString stringByAppendingString:@"-InputGlucoseTimeStampKey"];
    NSString* glucoseDateStampKey = [localDateString stringByAppendingString:@"-InputGlucoseDateStampKey"];
    NSString* glucoseTimeStampArrayKey = [localDateString stringByAppendingString:@"-InputGlucoseDateStampArrayKey"];
    
    // for checking
    NSLog(@"ForTodayExtension- localDateString: %@", localDateString);
    NSLog(@"ForTodayExtension- localTimeString: %@", localTimeString);
    NSLog(@"ForTodayExtension- utcDate: %@", dateToday);
    NSLog(@"ForTodayExtension- glucoseTimeStampKey: %@", glucoseTimeStampKey);
    
    // set DataSharing for App Extension
    NSUserDefaults *sharedDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.jp.co.arkray.e-SMBG"];
    //[shared setObject:glucoseTimeStampKey forKey:glucoseDateStampKey];
    
    // initialize empty arrays and dictionary
    NSMutableArray *timeStampsArray = [[NSMutableArray alloc]init];
    NSMutableArray *tempArray = [[NSMutableArray alloc]init];
    NSMutableDictionary *tempDic = [[NSMutableDictionary alloc]init];
    
    // save new user input with time stamp in dictionary
    [tempDic setObject:userGlucoseInput forKey:glucoseTimeStampKey];
    // save used time stamp in a seperate array
    [timeStampsArray addObject:glucoseTimeStampKey];
    // save new dictionary input to array of input recorded for today
    [tempArray addObject:tempDic];
    
    // save values for Data Sharing with extension
    [sharedDefaults setObject:tempArray forKey:glucoseDateStampKey];
    [sharedDefaults setObject:timeStampsArray forKey:glucoseTimeStampArrayKey];
    [sharedDefaults synchronize];
    
    // check stored values
    [self checkInputValues:glucoseTimeStampArrayKey dateStamp:glucoseDateStampKey];
}

//checker for stored values
-(void)checkInputValues: (NSString *)arrayKey dateStamp:(NSString *)dateStampKey
{
    // set DataSharing for App Extension
    NSUserDefaults *sharedDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.jp.co.arkray.e-SMBG"];
    
    // initialize empty arrays and dictionary
    NSMutableArray *timeStampsArray = [[sharedDefaults objectForKey:arrayKey] mutableCopy];
    NSMutableArray *tempArray = [[sharedDefaults objectForKey:dateStampKey] mutableCopy];
    
    //  for checking
    NSLog(@"ForTodayExtension- timeStampsArray@SAV: %@", timeStampsArray);
    NSLog(@"ForTodayExtension- tempArray@SAV: %@", tempArray);
//    NSLog(@"ForTodayExtension- tempDic: %@", tempDic);
}

