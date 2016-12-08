//
//  ViewController.swift
//  OwnRadio
//
//  Created by Roman Litoshko on 11/22/16.
//  Copyright © 2016 Roll'n'Code. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
	
	// MARK:  Outlets
	
	@IBOutlet weak var backgroundImageView: UIImageView!
	
	@IBOutlet weak var infoView: UIView!
	
	@IBOutlet weak var trackNameLbl: UILabel!
	@IBOutlet weak var authorNameLbl: UILabel!
	@IBOutlet weak var trackIDLbl: UILabel!
	@IBOutlet weak var deviceIdLbl: UILabel!
	@IBOutlet weak var exceptionLbl: UILabel!
	@IBOutlet var timerLabel: UILabel!
	@IBOutlet var versionLabel: UILabel!
	@IBOutlet var numberOfFiles: UILabel!
	
	@IBOutlet weak var playPauseBtn: UIButton!
	@IBOutlet weak var nextButton: UIButton!
	
	@IBOutlet weak var leftPlayBtnConstraint: NSLayoutConstraint!
	
	// MARK: Variables
	let defaultSession = URLSession(configuration: URLSessionConfiguration.default)
	var dataTask: URLSessionDataTask?
	var player: AudioPlayerManager!
	
	var isPlaying: Bool!
	var visibleInfoView: Bool!
	
	var timer = Timer()
	
	let playBtnConstraintConstant = CGFloat(15.0)
	let pauseBtnConstraintConstant = CGFloat(10.0)
	
	// MARK: Override
	override func viewDidLoad() {
		super.viewDidLoad()
		self.authorNameLbl.text = "ownRadio"
		self.trackNameLbl.text = "" 
		//get version of app
		if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
			
			if (Bundle.main.infoDictionary?["CFBundleVersion"] as? String) != nil {
				self.versionLabel.text =  "v" + version
			}
		}
		
		
		self.player = AudioPlayerManager.sharedInstance
		
		self.deviceIdLbl.text = (UserDefaults.standard.object(forKey: "UUIDDevice") as! String)
		self.visibleInfoView = false
		
		DispatchQueue.global(qos: .background).async {
				self.downloadTracks()
		}
		getCountFilesInCache()
		
		NotificationCenter.default.addObserver(self, selector: #selector(crashNetwork(_:)), name: NSNotification.Name.AVPlayerItemFailedToPlayToEndTime, object: self.player.playerItem)
		NotificationCenter.default.addObserver(self, selector: #selector(songDidPlay), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
	}
	
	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
		NotificationCenter.default.removeObserver(self, name:  NSNotification.Name.AVPlayerItemFailedToPlayToEndTime, object: nil)
		NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: self.player.playerItem)
	}
	
	override func remoteControlReceived(with event: UIEvent?) {
		
		if event?.type == UIEventType.remoteControl {
			switch event!.subtype {
			case UIEventSubtype.remoteControlPause:
				changePlayBtnState()
			case .remoteControlPlay:
				
				changePlayBtnState()
				
			case .remoteControlTogglePlayPause:
				break
			//				AudioPlayerManager.sharedInstance.playOrPause()
			case .remoteControlNextTrack:
				player.skipSong(complition: {
					DispatchQueue.main.async {
						self.updateUI()
					}
				})
			default:
				break
			}
		}
	}
	
	
	func downloadTracks() {
		guard currentReachabilityStatus != NSObject.ReachabilityStatus.notReachable else {
			return
		}
		Downloader.load() {
			
		}
	}
	
	// MARK: Notification Selectors
	func songDidPlay() {
		self.player.nextTrack { [unowned self] in
			DispatchQueue.main.async {
				self.updateUI()
			}
		}
	}
	
	func crashNetwork(_ notification: Notification) {
		self.playPauseBtn.setImage(UIImage(named: "playImg"), for: UIControlState.normal)
		self.leftPlayBtnConstraint.constant = pauseBtnConstraintConstant
		self.trackIDLbl.text = ""
		self.exceptionLbl.text = notification.description
	}
	
	func changePlayBtnState() {
		//		if currentReachabilityStatus == NSObject.ReachabilityStatus.notReachable {
		//			self.exceptionLbl.text = "Have not internet connection"
		//		} else {
		if player.isPlaying == true {
			player.pauseSong(complition: {
				DispatchQueue.main.async {
					self.updateUI()
				}
			})
		}else {
			player.resumeSong(complition: { [unowned self] in
				DispatchQueue.main.async {
					self.updateUI()
				}
				})
		}
		//		}
	}
	
	func getCountFilesInCache () {
		do {
			
			let docUrl = NSURL(string:FileManager.documentsDir()) as! URL
			let directoryContents = try FileManager.default.contentsOfDirectory(at: docUrl, includingPropertiesForKeys: nil, options: [])
			//			print(directoryContents)
			
			
			let mp3Files = directoryContents.filter{ $0.pathExtension == "mp3" }
			self.numberOfFiles.text = String.init(format:"%d", mp3Files.count)
			
		} catch let error as NSError {
			print(error.localizedDescription)
		}
	}
	
	func updateUI() {
		self.trackIDLbl.text = self.player.playingSong.trackID
		self.trackNameLbl.text = self.player.playingSong.name
		self.authorNameLbl.text = self.player.playingSong.artistName
		
		if self.player.isPlaying == false {
			self.playPauseBtn.setImage(UIImage(named: "playImg"), for: UIControlState.normal)
			self.leftPlayBtnConstraint.constant = playBtnConstraintConstant
		} else {
			self.playPauseBtn.setImage(UIImage(named: "pauseImg"), for: UIControlState.normal)
			self.leftPlayBtnConstraint.constant = pauseBtnConstraintConstant
			
		}
		self.exceptionLbl.text = ""
	}
	
	// MARK: Actions
	
	@IBAction func tripleTapAction(_ sender: AnyObject) {
		if self.infoView.isHidden == true {
			
			self.infoView.isHidden = false
			self.visibleInfoView = false
		}else {
			self.infoView.isHidden = true
			self.visibleInfoView = true
		}
		
	}
	
	@IBAction func nextTrackButtonPressed() {
		self.player.skipSong { [unowned self] in
			
			DispatchQueue.main.async { [unowned self] in
				self.updateUI()
			}
		}
		self.player.isPlaying = true
		getCountFilesInCache()
//		if currentReachabilityStatus != NSObject.ReachabilityStatus.notReachable {
//			DispatchQueue.global(qos: .background).async {
//				self.downloadTracks()
//			}
//		}
	}
	
	@IBAction func playBtnPressed() {
		changePlayBtnState()
		getCountFilesInCache()
	}
	
}

