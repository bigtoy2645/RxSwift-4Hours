//
//  MenuListViewModel.swift
//  RxSwift+MVVM
//
//  Created by yurim on 2021/07/15.
//  Copyright © 2021 iamchiwon. All rights reserved.
//

import Foundation
import RxSwift

/// UI와 관련된 작업은 에러가 나도 끊어지지 않아야 하므로 Subject 대신 RxRelay의 Relay를 사용한다.
/// 에러를 반환하지 않으므로 onNext 뿐이 없음. accpet로 대체함.

class MenuListViewModel {
    
    /// Subject : Observable + 외부에서 값을 변경할 수 있음.
    var menuObservable = BehaviorSubject<[Menu]>(value: [])
    
    lazy var itemsCount = menuObservable.map {
        $0.map { $0.count }.reduce(0, +)
    }
    lazy var totalPrice = menuObservable.map {
        $0.map { $0.price * $0.count }.reduce(0, +)
    }
    
    init() {
        _ = APIService.fetchAllMenusRx()
            .map { data -> [MenuItem] in
                struct Response: Decodable {
                    let menus: [MenuItem]
                }
                guard let response = try? JSONDecoder().decode(Response.self, from: data) else {
                    throw NSError(domain: "Decoding error", code: -1, userInfo: nil)
                }
                return response.menus
            }
            .map { menuitems in
                var menus: [Menu] = []
                menuitems.enumerated().forEach { index, item in
                    let menu = Menu.fromMenuItems(id: index, item: item)
                    menus.append(menu)
                }
                return menus
            }
            .take(1)
            .subscribe(onNext: {
                self.menuObservable.onNext($0)
            })
    }
    
    func clearAllItemSelections() {
        _ = menuObservable
            .map { menus in
                return menus.map { menu in
                    Menu(id: menu.id, name: menu.name, price: menu.price, count: 0)
                }
            }
            .take(1)
            .subscribe(onNext: {
                self.menuObservable.onNext($0)
            })
    }
    
    func changeCount(item: Menu, increase: Int) {
        _ = menuObservable
            .map { $0.map { menu in
                    if menu.id == item.id {
                        return Menu(id:menu.id,
                                    name: menu.name,
                                    price: menu.price,
                                    count: max(menu.count + increase, 0))
                    } else {
                        return menu
                    }
                }
            }
            .take(1)
            .subscribe(onNext: {
                self.menuObservable.onNext($0)
            })
    }
}
