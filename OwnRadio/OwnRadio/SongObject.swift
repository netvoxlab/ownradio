//
//  SongObject.swift
//  OwnRadio
//
//  Created by Roman Litoshko on 11/30/16.
//  Copyright © 2016 Roll'n'Code. All rights reserved.
//

import Foundation

class SongObject {
	var name: String!
	var artistName: String!
	var trackID: String!
	var trackLength: Float!
	var methodId: String!
	
	
	func initWithDict(dict:Dictionary<String,AnyObject>) {
		
		self.name = dict["name"] as? String
		self.trackID = dict["id"] as! String!
		self.trackLength =  NSString(string: dict["length"] as! String).floatValue
		self.artistName = dict["artist"] as? String!
		self.methodId = dict["methodid"] as? String!

	}
}