import { Component } from '@angular/core';
import { MenuPageComponent } from './features/menu/menu-page.component';

@Component({
  selector: 'app-root',
  imports: [MenuPageComponent],
  templateUrl: './app.html',
  styleUrl: './app.scss'
})
export class App {
}
