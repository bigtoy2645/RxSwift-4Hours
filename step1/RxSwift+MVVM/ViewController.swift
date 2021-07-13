//
//  ViewController.swift
//  RxSwift+MVVM
//
//  Created by iamchiwon on 05/08/2019.
//  Copyright © 2019 iamchiwon. All rights reserved.
//

import RxSwift
import SwiftyJSON
import UIKit

let MEMBER_LIST_URL = "https://my.api.mockaroo.com/members_with_avatar.json?key=44ce18f0"

class 나중에생기는데이터<T> {                            // Observable
    private let task: (@escaping (T) -> Void) -> Void
    
    init(task: @escaping (@escaping (T) -> Void) -> Void) {
        self.task = task
    }
    
    func 나중에오면(_ f: @escaping (T) -> Void) {    // subscribe
        task(f)
    }
}

class ViewController: UIViewController {
    @IBOutlet var timerLabel: UILabel!
    @IBOutlet var editView: UITextView!

    override func viewDidLoad() {
        super.viewDidLoad()
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.timerLabel.text = "\(Date().timeIntervalSince1970)"
        }
    }

    private func setVisibleWithAnimation(_ v: UIView?, _ s: Bool) {
        guard let v = v else { return }
        UIView.animate(withDuration: 0.3, animations: { [weak v] in
            v?.isHidden = !s
        }, completion: { [weak self] _ in
            self?.view.layoutIfNeeded()
        })
    }
    
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    
    /* Observable의 생명주기
     1. Create
     2. Subscribe(실행 시점)
     3. onNext / onError
     ----- 끝 -----
     4. onCompleted / onError
     5. Disposed
     
     재사용 안됨.
     Operator 동작 방법 해석 : http://reactivex.io/documentation/operators/observeon.html
     */
    
    // MARK: - Supar API 사용한 처리
    
    func downloadJSON(_ url: String) -> Observable<String?> {
        /// 1. 비동기로 생기는 데이터를 Observable로 감싸서 return하는 방법
        return Observable.create { emitter in
            let url = URL(string: MEMBER_LIST_URL)!
            let task = URLSession.shared.dataTask(with: url) { data, _, err in
                guard err == nil else {
                    emitter.onError(err!)
                    return
                }
                
                if let dat = data, let json = String(data: dat, encoding: .utf8) {
                    emitter.onNext(json)
                }
                
                emitter.onCompleted()
            }
            
            task.resume()
            
            return Disposables.create() {
                task.cancel()
            }
        }
    }

    @IBAction func onLoad() {
        editView.text = ""
        setVisibleWithAnimation(self.activityIndicator, true)
        
        /// 2. Observable로 오는 데이터를 받아서 처리하는 방법
        _ = downloadJSON_3(MEMBER_LIST_URL)
            .observeOn(MainScheduler.instance)  // operator : Observable에서 subscribe로 전달되는 중간에 데이터를 바꾸는 것
            .subscribe(onNext: {json in
                self.editView.text = json
                self.setVisibleWithAnimation(self.activityIndicator, false)
            })
    }
    
    // MARK: - Sugar API
    
    func downloadJSON_4(_ url: String) -> Observable<String?> {
        return Observable.just("Hello World")
        //return Observable.from(["Hello", "World"])
    }

    @IBAction func onLoad_4() {
        editView.text = ""
        setVisibleWithAnimation(self.activityIndicator, true)
        
        downloadJSON(MEMBER_LIST_URL).subscribe(onNext: { print($0 ?? "")},
                                                onCompleted: { print("Complete")})
    }
    
    // MARK: - RxSwift 사용한 비동기 처리 + 오류 처리
    
    func downloadJSON_3(_ url: String) -> Observable<String?> {
        /// 1. 비동기로 생기는 데이터를 Observable로 감싸서 return하는 방법
        return Observable.create { emitter in
            let url = URL(string: MEMBER_LIST_URL)!
            let task = URLSession.shared.dataTask(with: url) { data, _, err in
                guard err == nil else {
                    emitter.onError(err!)
                    return
                }
                
                if let dat = data, let json = String(data: dat, encoding: .utf8) {
                    emitter.onNext(json)
                }
                
                emitter.onCompleted()
            }
            
            task.resume()
            
            return Disposables.create() {
                task.cancel()
            }
        }
    }

    @IBAction func onLoad_3() {
        editView.text = ""
        setVisibleWithAnimation(self.activityIndicator, true)
        
        /// 2. Observable로 오는 데이터를 받아서 처리하는 방법
        ///
        /// subscribe의 클로저에서 self를 참조하므로 reference count가 증가하여 순환 참조가 발생함.
        /// f.onNext(json) 이후 f.onCompleted()를 호출하면 클로저를 탈출하여 reference count가 감소하고 순환 참조가 발생하지 않음.
        /// => Observable 해제되면 클로저가 종료되어 순환 참조가 발생하지 않음.
        /// 생명주기에서 알 수 있듯이 onCompleted / onError / Disposed 일 때 Observable이 해제됨.
        
        downloadJSON_3(MEMBER_LIST_URL)
            .debug()
            .subscribe { event in
                switch event {
                case .next(let json):
                    DispatchQueue.main.async {
                        self.editView.text = json
                        self.setVisibleWithAnimation(self.activityIndicator, false)
                    }
                case .completed:
                    break
                case .error:
                    break
            }
        }
        
        // 작업을 버리다.
        //disposable.dispose()
    }
    
    // MARK: - RxSwift 사용한 비동기 처리
    
    /// 비동기 반환 값을 completion이 아닌 return 값으로 받아 처리하고 싶을 때
    /// PromiseKit
    /// Bolt
    /// RxSwift
    
    func downloadJSON_2(_ url: String) -> Observable<String?> {
        /// 1. 비동기로 생기는 데이터를 Observable로 감싸서 return하는 방법
        return Observable.create { f in
            DispatchQueue.global().async {
                let url = URL(string: MEMBER_LIST_URL)!
                let data = try! Data(contentsOf: url)
                let json = String(data: data, encoding: .utf8)
                DispatchQueue.main.async {
                    f.onNext(json)
                }
            }
            
            return Disposables.create()
        }
    }

    @IBAction func onLoad_2() {
        editView.text = ""
        setVisibleWithAnimation(self.activityIndicator, true)
        
        /// 2. Observable로 오는 데이터를 받아서 처리하는 방법
        /// subscribe의 클로저에서 self를 참조하므로 reference count가 증가하여 순환 참조가 발생함.
        /// f.onNext(json) 이후 f.onCompleted()를 호출하면 클로저를 탈출하여 reference count가 감소하고 순환 참조가 발생하지 않음.
        _ = downloadJSON_2(MEMBER_LIST_URL)
            .subscribe { event in
                switch event {
                case .next(let json):
                    self.editView.text = json
                    self.setVisibleWithAnimation(self.activityIndicator, false)
                case .completed:
                    break
                case .error:
                    break
            }
        }
        
        // 작업을 버리다.
        //disposable.dispose()
    }
    
    // MARK: - RxSwift 없이 비동기 처리
    
    /// @escaping : 본체 함수가 끝난 뒤 나중에 실행된다.
    /// (String?) -> Void)? 옵셔널 함수일 경우 @escaping이 default이므로 에러가 발생하지 않는다.
    
    func downloadJSON_1(_ url: String, _ completion: @escaping ((String?) -> Void)) {
        DispatchQueue.global().async {
            let url = URL(string: MEMBER_LIST_URL)!
            let data = try! Data(contentsOf: url)
            let json = String(data: data, encoding: .utf8)
            DispatchQueue.main.async {
                completion(json)
            }
        }
    }

    @IBAction func onLoad_1() {
        editView.text = ""
        self.setVisibleWithAnimation(self.activityIndicator, true)
        
        self.downloadJSON_1(MEMBER_LIST_URL) { json in
            self.editView.text = json
            self.setVisibleWithAnimation(self.activityIndicator, false)
        }
    }
}
